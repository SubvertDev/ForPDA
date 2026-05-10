//
//  TicketStatusHistoryFeature.swift
//  ForPDA
//
//  Created by Xialtal on 10.05.26.
//

import Foundation
import ComposableArchitecture
import TicketClient
import Models

@Reducer
public struct TicketStatusHistoryFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let ticketId: Int
        
        var history: [TicketStatusHistory] = []
        
        var isLoading = false
        
        public init(
            ticketId: Int
        ) {
            self.ticketId = ticketId
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            
            case closeButtonTapped
            
            case handlerButtonTapped(Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadHistory
            case historyResponse(Result<[TicketStatusHistory], any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openUser(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.ticketClient) private var ticketClient
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadHistory))
                
            case .view(.closeButtonTapped):
                return .run { _ in await dismiss() }
                
            case let .view(.handlerButtonTapped(id)):
                return .send(.delegate(.openUser(id)))
                
            case .internal(.loadHistory):
                state.isLoading = true
                return .run { [id = state.ticketId] send in
                    let response = try await ticketClient.getTicketStatusHistory(ticketId: id)
                    await send(.internal(.historyResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.historyResponse(.failure(error))))
                }
                
            case let .internal(.historyResponse(.success(response))):
                state.history = response
                state.isLoading = false
                return .none
                
            case let .internal(.historyResponse(.failure(error))):
                print(error)
                state.isLoading = false
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
