//
//  QMSFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 10.05.2026.
//

import AnalyticsClient
import ComposableArchitecture

extension QMSFeature {
    
    struct Analytics: Reducer {
        typealias State = QMSFeature.State
        typealias Action = QMSFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { _, action in
                switch action {
                case .view(.onAppear), .internal, .delegate, .binding, .alert:
                    break
                    
                case let .view(.sendMessageButtonTapped(draft)):
                    analytics.log(QMSEvent.sendMessageTapped(isEmpty: draft.text.isEmpty))
                    
                case .view(.loadMoreTriggered):
                    analytics.log(QMSEvent.loadMoreTriggered)
                    
                case let .view(.urlTapped(url)):
                    analytics.log(QMSEvent.linkTapped(url))
                }
                
                return .none
            }
        }
    }
}
