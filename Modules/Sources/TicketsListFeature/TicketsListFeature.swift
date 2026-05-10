//
//  TicketsListFeature.swift
//  ForPDA
//
//  Created by Xialtal on 8.05.26.
//

import Foundation
import ComposableArchitecture
import TicketClient
import Models
import PersistenceKeys
import PageNavigationFeature
import ToastClient
import PasteboardClient
import CacheClient
import TicketStatusHistoryFeature

@Reducer
public struct TicketsListFeature: Reducer, Sendable {
    
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
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        
        @Presents public var destination: Destination.State?
        
        var userSessionNickname: String?
        var pageNavigation = PageNavigationFeature.State(type: .tickets)
        
        public let type: TicketsListType
        
        var tickets: IdentifiedArrayOf<TicketsList.TicketSimplified> = []
        
        var isLoading = false
        var isRefreshing = false
        
        public init(
            type: TicketsListType
        ) {
            self.type = type
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)
        case pageNavigation(PageNavigationFeature.Action)
        
        case view(View)
        public enum View {
            case onFirstAppear
            case onRefresh
            
            case ticketButtonTapped(Int)
            
            case contextMenu(TicketsListContextMenuAction)
            case contextTicketMenu(TicketContextMenuAction, Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case refresh
            case initUserSessionNickname(String)
            case loadTickets(offset: Int)
            case ticketsResponse(Result<TicketsList, any Error>)
            case changeTicketStatusResponse(Result<(Int, TicketStatus, TicketStatusChangeResponse), any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openUser(Int)
            case openTicket(Int)
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
        
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding(\.appSettings.tickets.isSortByForums),
                 .binding(\.appSettings.tickets.isShowOnlyMine):
                return .send(.internal(.refresh))
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(.internal(.loadTickets(offset: newOffset)))
                
            case let .destination(.presented(.statusHistory(.delegate(.openUser(id))))):
                return .send(.delegate(.openUser(id)))
                
            case .pageNavigation, .binding, .delegate, .destination:
                return .none
                
            case .view(.onFirstAppear):
                return .run { [session = state.userSession] send in
                    if let session, let user = cacheClient.getUser(session.userId) {
                        await send(.internal(.initUserSessionNickname(user.nickname)))
                    }
                    await send(.internal(.loadTickets(offset: 0)))
                }
                
            case .view(.onRefresh):
                guard !state.isLoading else { return .none }
                return .send(.internal(.refresh))
                
            case let .view(.ticketButtonTapped(id)):
                return .send(.delegate(.openTicket(id)))
                
            case let .view(.contextMenu(action)):
                switch action {
                case .copyLink:
                    let type = switch state.type {
                    case .list: ""
                    case .topic(let id): "&only-topic=\(id)"
                    }
                    let offset = state.pageNavigation.offset > 0 ? "&st=\(state.pageNavigation.offset)" : ""
                    pasteboardClient.copy("https://4pda.to/forum/index.php?act=ticket\(offset)\(type)")
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                }
                
            case let .view(.contextTicketMenu(action, ticketId)):
                switch action {
                case .changeStatus(let status):
                    return .run { [handlerId = state.userSession?.userId] send in
                        let response = try await ticketClient.changeTicketStatus(
                            id: ticketId,
                            handlerId: handlerId ?? 0,
                            status: status
                        )
                        await send(.internal(.changeTicketStatusResponse(.success((ticketId, status, response)))))
                    } catch: { error, send in
                        await send(.internal(.changeTicketStatusResponse(.failure(error))))
                    }
                    
                case .statusHistory:
                    state.destination = .statusHistory(TicketStatusHistoryFeature.State(ticketId: ticketId))
                    
                case .openAuthor(let authorId):
                    return .send(.delegate(.openUser(authorId)))
                    
                case .copyLink:
                    pasteboardClient.copy("https://4pda.to/forum/index.php?act=ticket&s=thread&t_id=\(ticketId)")
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                }
                return .none
                
            case let .internal(.initUserSessionNickname(name)):
                state.userSessionNickname = name
                return .none
                
            case .internal(.refresh):
                state.isRefreshing = true
                return .send(.internal(.loadTickets(offset: state.pageNavigation.offset)))
                
            case let .internal(.loadTickets(offset)):
                if !state.isRefreshing {
                    state.isLoading = true
                }
                let forId = switch state.type {
                case .list: 0
                case .topic(let id): id
                }
                return .run { [
                    amount = state.appSettings.ticketsPerPage,
                    ticketsSettings = state.appSettings.tickets
                ] send in
                    let request = TicketsListRequest(
                        forId: forId,
                        offset: offset,
                        amount: amount,
                        isSortByForums: ticketsSettings.isSortByForums,
                        isShowOnlyMine: ticketsSettings.isShowOnlyMine
                    )
                    let respone = try await ticketClient.getTicketsList(request)
                    await send(.internal(.ticketsResponse(.success(respone))))
                } catch: { error, send in
                    await send(.internal(.ticketsResponse(.failure(error))))
                }
                
            case let .internal(.ticketsResponse(.success(response))):
                state.tickets = .init(uniqueElements: response.tickets)
                state.pageNavigation.count = response.availableCount
                state.isLoading = false
                state.isRefreshing = false
                return .none
                
            case let .internal(.ticketsResponse(.failure(error))):
                print(error)
                state.isLoading = false
                state.isRefreshing = false
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
                
            case let .internal(.changeTicketStatusResponse(.success((ticketId, status, .success)))):
                if let session = state.userSession, let handlerName = state.userSessionNickname {
                    let info: (Int, String, Date?) = switch status {
                    case .processed:    (session.userId, handlerName, Date.now)
                    case .processing:   (session.userId, handlerName, nil)
                    case .notProcessed: (0, "", nil)
                    }
                    state.tickets[ticketId].info.status = status
                    state.tickets[ticketId].info.handlerId = info.0
                    state.tickets[ticketId].info.handlerName = info.1
                    state.tickets[ticketId].info.processedAt = info.2
                }
                return .run { _ in
                    await toastClient.showToast(ToastMessage(text: Localization.statusChanged, haptic: .success))
                }
                           
            case let .internal(.changeTicketStatusResponse(.success((ticketId, _, .failure(reason))))):
                switch reason {
                case .handlerChanged(let id, let name):
                    state.tickets[ticketId].info.handlerId = id
                    state.tickets[ticketId].info.handlerName = name
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
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension TicketsListFeature.Destination.State: Equatable {}
