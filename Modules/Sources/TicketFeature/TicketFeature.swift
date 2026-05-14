//
//  TicketFeature.swift
//  ForPDA
//
//  Created by Xialtal on 5.05.26.
//

import Foundation
import ComposableArchitecture
import TicketClient
import Models
import PasteboardClient
import PersistenceKeys
import ToastClient
import CacheClient
import TicketStatusHistoryFeature

@Reducer
public struct TicketFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Localizations
    
    private enum Localization {
        static let linkCopied = LocalizedStringResource("Link copied", bundle: .module)
        static let commentAdded = LocalizedStringResource("Comment added", bundle: .module)
        static let commentEdited = LocalizedStringResource("Comment edited", bundle: .module)
        static let commentDeleted = LocalizedStringResource("Comment deleted", bundle: .module)
        static let handlerChanged = LocalizedStringResource("The ticket's handler has changed, please try again", bundle: .module)
        static let unableChangeStatus = LocalizedStringResource("Unable to change ticket status", bundle: .module)
        static let statusChanged = LocalizedStringResource("Ticket status changed", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        @ReducerCaseIgnored
        case alert(AlertState<Alert>)
        case statusHistory(TicketStatusHistoryFeature)
        
        case addComment
        @ReducerCaseIgnored
        case editComment(Int)
        
        @CasePathable
        public enum Action {
            case alert(Alert)
            case statusHistory(TicketStatusHistoryFeature.Action)
        }
        
        @CasePathable
        public enum Alert: Equatable {
            case deleteComment(Int)
        }
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.userSession) var userSession: UserSession?
        var userSessionNickname: String?
        
        @Presents public var destination: Destination.State?
        
        public let id: Int
        
        var ticket: Ticket?
        var isLoading = false
        var isRefreshing = false
        
        var alertInput = ""
        
        public init(
            id: Int
        ) {
            self.id = id
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        
        case view(View)
        public enum View {
            case onAppear
            case onRefresh
            
            case commentButtonTapped(Int, isAdd: Bool)
            case changeStatusButtonTapped(TicketStatus)
            case showAddCommentAlertButtonTapped
            
            case urlTapped(URL)
            case commentAuthorButtonTapped(Int)
            
            case contextMenu(TicketContextMenuAction)
            case contextCommentMenu(TicketCommentContextMenuAction)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case refresh
            case loadTicket
            case ticketResponse(Result<Ticket, any Error>)
            case changeTicketStatusResponse(Result<(TicketStatus, TicketStatusChangeResponse), any Error>)
            case commentTicketResponse(Result<(Bool, Bool), any Error>)
            
            case initUserSessionNickname(String)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
            case openUser(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.ticketClient) private var ticketClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.openURL) private var openURL
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .destination(.presented(.statusHistory(.delegate(.openUser(id))))):
                state.destination = nil
                return .send(.delegate(.openUser(id)))
                
            case let .destination(.presented(.alert(.deleteComment(id)))):
                return .run { [ticketId = state.id] send in
                    let status = try await ticketClient.deleteComment(id, ticketId)
                    let postDeletedToast = ToastMessage(
                        text: Localization.commentDeleted,
                        haptic: .success
                    )
                    await toastClient.showToast(status ? postDeletedToast : .whoopsSomethingWentWrong)
                    await send(.internal(.refresh))
                }
                
            case .delegate, .destination, .binding:
                return .none
                
            case .view(.onAppear):
                return .run { [session = state.userSession] send in
                    if let session, let user = cacheClient.getUser(session.userId) {
                        await send(.internal(.initUserSessionNickname(user.nickname)))
                    }
                    await send(.internal(.loadTicket))
                }
                
            case .view(.onRefresh):
                return .send(.internal(.refresh))
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url)))
                
            case let .view(.commentAuthorButtonTapped(id)):
                return .send(.delegate(.openUser(id)))
                
            case let .view(.contextMenu(action)):
                guard let ticket = state.ticket else { return .none }
                switch action {
                case .statusHistory:
                    state.destination = .statusHistory(TicketStatusHistoryFeature.State(
                        ticketId: state.id
                    ))
                    
                case .openAuthor:
                    return .send(.delegate(.openUser(ticket.info.authorId)))
                    
                case .copyLink:
                    pasteboardClient.copy("https://4pda.to/forum/index.php?act=ticket&s=thread&t_id=\(state.id)")
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                }
                return .none
                
            case let .view(.contextCommentMenu(action)):
                switch action {
                case .edit(let commentId):
                    if let comment = state.ticket?.comments.first(where: { $0.id == commentId }) {
                        state.alertInput = comment.content
                    }
                    state.destination = .editComment(commentId)
                    
                case .delete(let commentId):
                    state.destination = .alert(.deleteCommentConfirmation(commentId: commentId))
                }
                return .none
                
            case .view(.showAddCommentAlertButtonTapped):
                state.destination = .addComment
                return .none
                
            case let .view(.commentButtonTapped(commentId, isAdd)):
                return .run { [ticketId = state.id, text = state.alertInput] send in
                    let status = try await ticketClient.modifyComment(commentId, ticketId, text)
                    await send(.internal(.commentTicketResponse(.success((isAdd, status)))))
                } catch: { error, send in
                    await send(.internal(.commentTicketResponse(.failure(error))))
                }
                
            case let .view(.changeStatusButtonTapped(status)):
                return .run { [ticketId = state.id, handlerId = state.ticket?.info.handlerId] send in
                    let response = try await ticketClient.changeTicketStatus(ticketId, handlerId ?? 0, status)
                    await send(.internal(.changeTicketStatusResponse(.success((status, response)))))
                } catch: { error, send in
                    await send(.internal(.changeTicketStatusResponse(.failure(error))))
                }
                
            case .internal(.refresh):
                state.isRefreshing = true
                return .send(.internal(.loadTicket))
                
            case let .internal(.changeTicketStatusResponse(.success((status, .success)))):
                if let session = state.userSession, let handlerName = state.userSessionNickname {
                    let info: (Int, String, Date?) = switch status {
                    case .processed:    (session.userId, handlerName, Date.now)
                    case .processing:   (session.userId, handlerName, nil)
                    case .notProcessed: (0, "", nil)
                    }
                    state.ticket?.info.status = status
                    state.ticket?.info.handlerId = info.0
                    state.ticket?.info.handlerName = info.1
                    state.ticket?.info.processedAt = info.2
                }
                return .run { _ in
                    await toastClient.showToast(ToastMessage(text: Localization.statusChanged, haptic: .success))
                }
                           
            case let .internal(.changeTicketStatusResponse(.success((_, .failure(reason))))):
                switch reason {
                case .handlerChanged(let id, let name):
                    state.ticket?.info.handlerId = id
                    state.ticket?.info.handlerName = name
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.handlerChanged, isError: true, haptic: .error))
                    }
                    
                case .other:
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.unableChangeStatus, isError: true, haptic: .error))
                    }
                }
                
            case let .internal(.changeTicketStatusResponse(.failure(error))):
                print(error)
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case let .internal(.commentTicketResponse(.success((isAdd, status)))):
                state.alertInput = ""
                return .run { send in
                    let commentToast = ToastMessage(
                        text: isAdd ? Localization.commentAdded : Localization.commentEdited,
                        haptic: .success
                    )
                    await toastClient.showToast(status ? commentToast : .whoopsSomethingWentWrong)
                    await send(.internal(.refresh))
                }
                
            case let .internal(.commentTicketResponse(.failure(error))):
                print(error)
                state.alertInput = ""
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case .internal(.loadTicket):
                if !state.isRefreshing {
                    state.isLoading = true
                }
                return .run { [id = state.id] send in
                    let response = try await ticketClient.getTicket(id)
                    await send(.internal(.ticketResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.ticketResponse(.failure(error))))
                }
                
            case let .internal(.ticketResponse(.success(response))):
                state.ticket = response
                state.isLoading = false
                state.isRefreshing = false
                return .none
                
            case let .internal(.ticketResponse(.failure(error))):
                print(error)
                state.isLoading = false
                state.isRefreshing = false
                return .none
                
            case let .internal(.initUserSessionNickname(name)):
                state.userSessionNickname = name
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension TicketFeature.Destination.State: Equatable {}

// MARK: - Alert Extension

extension AlertState where Action == TicketFeature.Destination.Alert {
    
    nonisolated static func deleteCommentConfirmation(commentId: Int) -> AlertState {
        return AlertState(
            title: {
                TextState("Are you sure, that you want to delete this comment?", bundle: .module)
            },
            actions: {
                ButtonState(role: .destructive, action: .deleteComment(commentId)) {
                    TextState("Yes", bundle: .module)
                }
                ButtonState(role: .cancel) {
                    TextState("No", bundle: .module)
                }
            }
        )
    }
}
