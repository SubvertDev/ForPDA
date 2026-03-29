//
//  TopicEditFeature.swift
//  ForPDA
//
//  Created by Xialtal on 29.03.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct TopicEditFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let id: Int
        public var name: String
        public var description: String
        public var poll: Topic.Poll?
        
        public init(
            id: Int,
            name: String,
            description: String,
            poll: Topic.Poll? = nil
        ) {
            self.id = id
            self.name = name
            self.description = description
            self.poll = poll
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .none
            }
        }
    }
}
