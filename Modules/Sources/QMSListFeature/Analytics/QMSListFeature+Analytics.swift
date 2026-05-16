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
                    
                    // MARK: - Binding
                    
                case .binding:
                    break
                    
                    // MARK: - View
                    
                case .view(.onAppear):
                    break
                    
                case let .view(.chatRowTapped(chatId)):
                    analytics.log(QMSListEvent.chatTapped(chatId))
                    
                case let .view(.chatContextMenu(chatContextAction, _, _)):
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
                    
                case .view(.createChatButtonTapped):
                    analytics.log(QMSListEvent.createChatTapped)
                    
                case .view(.tryAgainButtonTapped):
                    analytics.log(QMSListEvent.tryAgainTapped)
                    
                    // MARK: - Destinations
                    
                case .createChat:
                    break
                    
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
