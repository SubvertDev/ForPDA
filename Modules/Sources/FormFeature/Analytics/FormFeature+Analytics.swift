//
//  WriteFormFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 13.12.2025.
//

import ComposableArchitecture
import AnalyticsClient

extension FormFeature {
    
    struct Analytics: Reducer {
        typealias State = FormFeature.State
        typealias Action = FormFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .binding, .destination, .rows, .internal:
                    break
                    
                case .delegate(.formSent):
                    analytics.log(FormEvent.formSent)
                    
                case .view(.publishButtonTapped):
                    analytics.log(FormEvent.publishTapped)
                    
                case .view(.cancelButtonTapped):
                    analytics.log(FormEvent.dismissTapped)
                    
                case .view(.previewButtonTapped):
                    analytics.log(FormEvent.previewTapped)
                    
                case .view:
                    break
                }
                
                return .none
            }
        }
    }
}
