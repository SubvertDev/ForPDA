//
//  NavigationSettingsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import ComposableArchitecture
import PersistenceKeys
import Models

@Reducer
public struct NavigationSettingsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        public var topicOpening: TopicOpeningStrategy
        public var floatingNavigation: Bool

        public init() {
            self.topicOpening = _appSettings.topicOpeningStrategy.wrappedValue
            self.floatingNavigation = _appSettings.floatingNavigation.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
        }
        
        case `internal`(Internal)
        public enum Internal {
            
        }
    }
    
    // MARK: - Dependency
    
    
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                break
                
            case .binding(\.topicOpening):
                state.$appSettings.topicOpeningStrategy.withLock { $0 = state.topicOpening }
                
            case .binding(\.floatingNavigation):
                state.$appSettings.floatingNavigation.withLock { $0 = state.floatingNavigation }
                
            case .binding:
                break
            }
            
            return .none
        }
    }
}
