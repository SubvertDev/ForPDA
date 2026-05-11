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

@Reducer
public struct TicketFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
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
        case view(View)
        public enum View {
            case onAppear
            
            case urlTapped(URL)
            case commentAuthorButtonTapped(Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadTicket
            case ticketResponse(Result<Ticket, any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
            case openUser(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.ticketClient) private var ticketClient
    @Dependency(\.openURL) private var openURL
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .delegate:
                return .none
                
            case .view(.onAppear):
                return .send(.internal(.loadTicket))
                
            case let .view(.urlTapped(url)):
                return .send(.delegate(.handleUrl(url)))
                
            case let .view(.commentAuthorButtonTapped(id)):
                return .send(.delegate(.openUser(id)))
                
            case .internal(.loadTicket):
                state.isLoading = true
                return .run { [id = state.id] send in
                    let response = try await ticketClient.getTicket(id: id)
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
            }
        }
    }
}
