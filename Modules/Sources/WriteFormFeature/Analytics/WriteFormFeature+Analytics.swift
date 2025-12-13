//
//  WriteFormFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 13.12.2025.
//

import ComposableArchitecture
import AnalyticsClient

extension WriteFormFeature {
    
    struct Analytics: Reducer {
        typealias State = WriteFormFeature.State
        typealias Action = WriteFormFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .binding, .destination, .internal:
                    break
                    
                case .delegate(.writeFormSent):
                    analytics.log(WriteFormEvent.writeFormSent)
                    
                case .view(.publishButtonTapped):
                    analytics.log(WriteFormEvent.publishTapped)
                    
                case .view(.dismissButtonTapped):
                    analytics.log(WriteFormEvent.dismissTapped)
                    
                case .view(.previewButtonTapped):
                    analytics.log(WriteFormEvent.previewTapped)
                    
                case .view:
                    break
                }
                
                return .none
            }
        }
    }
}
