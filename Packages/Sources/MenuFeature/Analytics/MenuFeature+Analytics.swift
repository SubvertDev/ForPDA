//
//  MenuFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension MenuFeature {
    
    struct Analytics: Reducer {
        typealias State = MenuFeature.State
        typealias Action = MenuFeature.Action
        
        @Dependency(\.analyticsClient) var analyticsClient
        
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .onTask, .alert, .notImplementedFeatureTapped, ._subscribeToUpdates, ._loadUserResult, .profileTapped:
                    break
                    
                case .settingsTapped:
                    analyticsClient.log(MenuEvent.settingsTapped)
                    
                case .appAuthorButtonTapped:
                    analyticsClient.log(MenuEvent.author4PDATapped)
                    
                case .telegramChangelogButtonTapped:
                    analyticsClient.log(MenuEvent.changelogTelegramTapped)
                    
                case .telegramChatButtonTapped:
                    analyticsClient.log(MenuEvent.chatTelegramTapped)
                    
                case .githubButtonTapped:
                    analyticsClient.log(MenuEvent.githubTapped)
                    
                case let ._userSessionUpdated(session):
                    analyticsClient.log(MenuEvent.userSessionUpdated(session?.userId))
                    
                case .delegate(.openAuth):
                    analyticsClient.log(MenuEvent.authTapped)
                    
                case .delegate(.openProfile):
                    analyticsClient.log(MenuEvent.profileTapped)
                }
                return .none
            }
        }
    }
}
