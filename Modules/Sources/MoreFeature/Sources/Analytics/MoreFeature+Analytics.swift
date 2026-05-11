//
//  MoreFeature+Analytics.swift
//  ForPDA
//
//  Created by Codex on 10.05.2026.
//

import AnalyticsClient
import ComposableArchitecture

extension MoreFeature {
    
    struct Analytics: Reducer {
        typealias State = MoreFeature.State
        typealias Action = MoreFeature.Action
        
        @Dependency(\.analyticsClient) var analytics
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .view(.onAppear), .internal, .delegate:
                    break
                    
                case .view(.profileButtonTapped):
                    analytics.log(MoreEvent.profileTapped(state.isLoggedIn))
                    
                case .view(.qmsButtonTapped):
                    analytics.log(MoreEvent.qmsTapped)
                    
                case .view(.mentionsButtonTapped):
                    analytics.log(MoreEvent.mentionsTapped)
                    
                case .view(.historyButtonTapped):
                    analytics.log(MoreEvent.historyTapped)
                    
                case .view(.devDBButtonTapped):
                    analytics.log(MoreEvent.devDBTapped)
                    
                case .view(.settingsButtonTapped):
                    analytics.log(MoreEvent.settingsTapped)
                    
                case .view(.supportOnBoostyButtonTapped):
                    analytics.log(MoreEvent.supportOnBoostyTapped)
                    
                case .view(.appDiscussionButtonTapped):
                    analytics.log(MoreEvent.appDiscussionTapped)
                    
                case .view(.telegramChatButtonTapped):
                    analytics.log(MoreEvent.telegramChatTapped)
                    
                case .view(.githubButtonTapped):
                    analytics.log(MoreEvent.githubTapped)
                    
                case .view(.logoutButtonTapped):
                    analytics.log(MoreEvent.logoutTapped)
                    
                case .alert(.presented(.confirmLogout)):
                    analytics.log(MoreEvent.logoutConfirmed)
                    
                case .alert, .auth:
                    break
                }
                
                return .none
            }
        }
    }
}
