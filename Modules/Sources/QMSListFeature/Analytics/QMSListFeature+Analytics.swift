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
                    
                case let .view(.chatContextMenu(chatContextAction, _)):
                    switch chatContextAction {
                    case .markAsReadButtonTapped:
                        break
                    case .deleteChatButtonTapped:
                        break
                    }
                    
                case let .view(.userRowTapped(userId)):
                    analytics.log(QMSListEvent.userTapped(userId, isExpandable: true))
                    
                case let .view(.userContextMenu(userContextAction, _)):
                    switch userContextAction {
                    case .createChatButtonTapped:
                        break
                    case .userProfileButtonTapped:
                        break
                    case .profileLinkButtonTapped:
                        break
                    case .addToBlacklistButtonTapped:
                        break
                    case .deleteAllChatsButtonTapped:
                        break
                    }
                    
                case let .view(.createChatButtonTapped(userId)):
                    analytics.log(QMSListEvent.createChatTapped(userId: userId))
                }
                
                return .none
            }
        }
    }
}
