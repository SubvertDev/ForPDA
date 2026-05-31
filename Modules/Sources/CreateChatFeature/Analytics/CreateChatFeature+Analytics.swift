//
//  Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 30.05.2026.
//


import AnalyticsClient
import ComposableArchitecture

extension CreateChatFeature {
    
    struct Analytics: Reducer {
        typealias State = CreateChatFeature.State
        typealias Action = CreateChatFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                    
                    // MARK: - Binding
                    
                case .binding:
                    break
                    
                    // MARK: - View
                    
                case .view(.viewTapped):
                    break
                    
                case .view(.searchUserSelected):
                    analytics.log(CreateChatEvent.searchUserSelected)
                    
                case .view(.sendButtonTapped):
                    analytics.log(CreateChatEvent.sendTapped)
                    
                case .view(.closeButtonTapped):
                    analytics.log(CreateChatEvent.closeTapped)
                    
                    // MARK: - Internal
                    
                case .internal:
                    break
                    
                    // MARK: - Delegate
                    
                case .delegate:
                    break
                }
                
                return .none
            }
        }
    }
}
