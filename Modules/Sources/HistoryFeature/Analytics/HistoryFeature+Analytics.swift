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
                case .view(.onFirstAppear), .delegate:
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
                    
                case .view(.onRefresh):
                    analytics.log(HistoryEvent.onRefresh)
                    
                case let .view(.topicTapped(topic, showUnread)):
                    analytics.log(HistoryEvent.topicTapped(topic.id, topic.name, showUnread))
                    
                case .internal(.refresh),
                     .internal(.loadHistory),
                     .internal(.historyResponse),
                     .internal(.markRead):
                    break
                }
                
                return .none
            }
        }
    }
}
