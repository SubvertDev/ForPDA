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
        static let handlerChanged = LocalizedStringResource("The ticket's handler has changed, please try again", bundle: .module)
        static let unableChangeStatus = LocalizedStringResource("Unable to change ticket status", bundle: .module)
        static let statusChanged = LocalizedStringResource("Ticket status changed", bundle: .module)
    }
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        case statusHistory(TicketStatusHistoryFeature)
        
        @CasePathable
        public enum Action {
            case statusHistory(TicketStatusHistoryFeature.Action)
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
        
        public init(
            id: Int
        ) {
            self.id = id
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case destination(PresentationAction<Destination.Action>)
        
        case view(View)
        public enum View {
            case onAppear
            
            case commentButtonTapped
            case changeStatusButtonTapped(TicketStatus)
            
            case urlTapped(URL)
            case commentAuthorButtonTapped(Int)
            
            case contextMenu(TicketContextMenuAction)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadTicket
            case ticketResponse(Result<Ticket, any Error>)
            case changeTicketStatusResponse(Result<(TicketStatus, TicketStatusChangeResponse), any Error>)
            
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
        Reduce<State, Action> { state, action in
            switch action {
            case let .destination(.presented(.statusHistory(.delegate(.openUser(id))))):
                return .send(.delegate(.openUser(id)))
                
            case .delegate, .destination:
                return .none
                
            case .view(.onAppear):
                return .run { [session = state.userSession] send in
                    if let session, let user = cacheClient.getUser(session.userId) {
                        await send(.internal(.initUserSessionNickname(user.nickname)))
                    }
                    await send(.internal(.loadTicket))
                }
                
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
                
            case .view(.commentButtonTapped):
                return .run { [ticketId = state.id] send in
                    let response = try await ticketClient.modifyComment(id: 0, ticketId: ticketId, text: "Xx")
                }
                
            case let .view(.changeStatusButtonTapped(status)):
                return .run { [ticketId = state.id, handlerId = state.userSession?.userId] send in
                    let response = try await ticketClient.changeTicketStatus(
                        id: ticketId,
                        handlerId: handlerId ?? 0,
                        status: status
                    )
                    await send(.internal(.changeTicketStatusResponse(.success((status, response)))))
                } catch: { error, send in
                    await send(.internal(.changeTicketStatusResponse(.failure(error))))
                }
                
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
                        await toastClient.showToast(ToastMessage(text: Localization.handlerChanged, haptic: .success))
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
                
            case .internal(.loadTicket):
                state.isLoading = true
                return .run { [id = state.id] send in
                    let response = try await ticketClient.getTicket(id)
                    await send(.internal(.ticketResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.ticketResponse(.failure(error))))
                }
                
            case let .internal(.ticketResponse(.success(response))):
                state.ticket = response
                state.isLoading = false
                return .none
                
            case let .internal(.ticketResponse(.failure(error))):
                print(error)
                state.isLoading = false
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
