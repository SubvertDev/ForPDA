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
                    
                case .view(.onRefresh):
                    analytics.log(QMSListEvent.onRefresh)
                    
                case .view(.chatRowTapped):
                    analytics.log(QMSListEvent.chatTapped)
                    
                case let .view(.chatContextMenu(chatContextAction, _, _)):
                    switch chatContextAction {
                    case .markAsReadButtonTapped:
                        break
                    case .deleteChatButtonTapped:
                        analytics.log(QMSListEvent.deleteChatTapped)
                    }
                    
                case .view(.userRowTapped):
                    analytics.log(QMSListEvent.userTapped(isExpandable: true))
                    
                case let .view(.userContextMenu(userContextAction, _)):
                    switch userContextAction {
                    case .createChatButtonTapped:
                        analytics.log(QMSListEvent.createChatInUserTapped)
                    case .userProfileButtonTapped:
                        analytics.log(QMSListEvent.userProfileTapped)
                    case .profileLinkButtonTapped:
                        break
                    case .addToBlacklistButtonTapped:
                        break
                    case .deleteAllChatsButtonTapped:
                        analytics.log(QMSListEvent.deleteAllChatsTapped)
                    }
                    
                case .view(.createChatButtonTapped):
                    analytics.log(QMSListEvent.createChatInRowTapped)
                    
                case .view(.tryAgainButtonTapped):
                    analytics.log(QMSListEvent.tryAgainTapped)
                    
                    // MARK: - Destinations
                    
                case .createChat:
                    break
                    
                case .alert(.presented(.confirmDeleteChat)):
                    analytics.log(QMSListEvent.deleteChatConfirmed)
                    
                case .alert(.presented(.confirmDeleteAllChats)):
                    analytics.log(QMSListEvent.deleteAllChatsConfirmed)
                    
                case .alert:
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
