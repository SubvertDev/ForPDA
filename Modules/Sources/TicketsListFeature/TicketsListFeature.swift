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

@Reducer
public struct TicketsListFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        public var pageNavigation = PageNavigationFeature.State(type: .tickets)
        
        public let type: TicketsListType
        
        var tickets: [TicketsList.TicketSimplified] = []
        var sort: TicketsListSort = []
        
        var isLoading = false
        
        public init(
            type: TicketsListType
        ) {
            self.type = type
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case pageNavigation(PageNavigationFeature.Action)
        
        case view(View)
        public enum View {
            case onFirstAppear
            case onRefresh
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadTickets(offset: Int)
            case ticketsResponse(Result<TicketsList, any Error>)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.ticketClient) private var ticketClient
    @Dependency(\.openURL) private var openURL
    @Dependency(\.toastClient) private var toastClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(.internal(.loadTickets(offset: newOffset)))
                
            case .pageNavigation:
                return .none
                
            case .view(.onFirstAppear):
                return .send(.internal(.loadTickets(offset: 0)))
                
            case .view(.onRefresh):
                guard !state.isLoading else { return .none }
                return .send(.internal(.loadTickets(offset: state.pageNavigation.offset)))
                
            case let .internal(.loadTickets(offset)):
                state.isLoading = true
                let forId = switch state.type {
                case .list: 0
                case .only(let forId): forId
                }
                return .run { [sort = state.sort, amount = state.appSettings.ticketsPerPage] send in
                    let request = TicketsListRequest(
                        forId: forId,
                        sort: sort,
                        offset: offset,
                        amount: amount
                    )
                    let respone = try await ticketClient.getTicketsList(request)
                    await send(.internal(.ticketsResponse(.success(respone))))
                } catch: { error, send in
                    await send(.internal(.ticketsResponse(.failure(error))))
                }
                
            case let .internal(.ticketsResponse(.success(response))):
                state.tickets = response.tickets
                state.pageNavigation.count = response.availableCount
                state.isLoading = false
                return .none
                
            case let .internal(.ticketsResponse(.failure(error))):
                print(error)
                state.isLoading = false
                return .run { _ in
                    await toastClient.showToast(.whoopsSomethingWentWrong)
                }
            }
        }
    }
}
