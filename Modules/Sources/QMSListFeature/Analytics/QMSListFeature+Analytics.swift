//
//  QMSListFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 10.05.2026.
//

import AnalyticsClient
import ComposableArchitecture

extension QMSListFeature {
    
    struct Analytics: Reducer {
        typealias State = QMSListFeature.State
        typealias Action = QMSListFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear), .internal, .delegate, .binding:
                    break
                    
                case let .view(.chatRowTapped(chatId)):
                    analytics.log(QMSListEvent.chatTapped(chatId))
                    
                case let .view(.userRowTapped(userId)):
                    let isExpanded = state.qms?.users.first(where: { $0.id == userId }).map { !$0.chats.isEmpty } ?? false
                    analytics.log(QMSListEvent.userTapped(userId, isExpandable: isExpanded))
                }
                
                return .none
            }
        }
    }
}
