//
//  HistoryFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 10.05.2026.
//

import ComposableArchitecture
import AnalyticsClient

extension HistoryFeature {
    
    struct Analytics: Reducer {
        typealias State = HistoryFeature.State
        typealias Action = HistoryFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear), .delegate:
                    break
                    
                case .pageNavigation(.offsetChanged(to: _)):
                    analytics.addBreadcrumb(
                        category: "HistoryPageNavigation",
                        message: nil,
                        data: [
                            "page": state.pageNavigation.page
                        ],
                        type: "ui"
                    )
                    
                case .pageNavigation:
                    break
                    
                case let .view(.topicTapped(topic, showUnread)):
                    analytics.log(HistoryEvent.topicTapped(topic.id, topic.name, showUnread))
                    
                case .internal(.loadHistory(offset: _)),
                        .internal(.historyResponse(_)):
                    break
                }
                
                return .none
            }
        }
    }
}
