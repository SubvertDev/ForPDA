//
//  TicketFeature.swift
//  ForPDA
//
//  Created by Xialtal on 5.05.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct TicketFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let type: TicketType
        
        public init(
            type: TicketType
        ) {
            self.type = type
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
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.openURL) var openURL
    
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
