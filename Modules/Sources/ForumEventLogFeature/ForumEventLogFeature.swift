//
//  ForumEventLogFeature.swift
//  ForPDA
//
//  Created by Xialtal on 14.05.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct ForumEventLogFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let id: Int
        public let type: ForumEventLogType
        
        public init(
            id: Int,
            type: ForumEventLogType
        ) {
            self.id = id
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

