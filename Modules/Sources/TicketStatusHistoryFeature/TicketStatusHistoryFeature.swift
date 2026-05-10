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
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.ticketClient) private var ticketClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .none
            }
        }
    }
}
