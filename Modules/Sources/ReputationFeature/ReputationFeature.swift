//
//  ReputationFeature.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct ReputationFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    
    // MARK: - Action
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
        }
    }
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> {state, action in
            switch action {
            case .view(.onAppear):
                return .none
            }
        }
    }
}
