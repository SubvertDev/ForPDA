//
//  SettingsFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension SettingsFeature {
    
    struct Analytics: Reducer {
        typealias State = SettingsFeature.State
        typealias Action = SettingsFeature.Action
        
        @Dependency(\.analyticsClient) var analyticsClient
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .destination, .binding, .delegate:
                    break
                    
                case .languageButtonTapped:
                    analyticsClient.log(SettingsEvent.languageTapped)
                    
                case .schemeButtonTapped:
                    analyticsClient.log(SettingsEvent.themeTapped)
                    
                case .notificationsButtonTapped:
                    analyticsClient.log(SettingsEvent.notificationsTapped)
                    
                case .onDeveloperMenuTapped:
                    return .none
                    
                case .safariExtensionButtonTapped:
                    analyticsClient.log(SettingsEvent.safariExtensionTapped)
                    
                case .copyDebugIdButtonTapped:
                    analyticsClient.log(SettingsEvent.copyDebugIdTapped)
                    
                // case .copyPushTokenButtonTapped:
                //     return .none

                case .clearCacheButtonTapped:
                    analyticsClient.log(SettingsEvent.clearCacheTapped)
                    
                case .supportOnBoostyButtonTapped:
                    analyticsClient.log(SettingsEvent.supportOnBoostyTapped)
                    
                case .appDiscussionButtonTapped:
                    analyticsClient.log(SettingsEvent.appDiscussion4pdaTapped)

                case .telegramChangelogButtonTapped:
                    analyticsClient.log(SettingsEvent.changelogTelegramTapped)

                case .telegramChatButtonTapped:
                    analyticsClient.log(SettingsEvent.chatTelegramTapped)

                case .githubButtonTapped:
                    analyticsClient.log(SettingsEvent.githubTapped)
                    
                case .checkVersionsButtonTapped:
                    analyticsClient.log(SettingsEvent.checkVersionsTapped)
                    
                case .notImplementedFeatureTapped:
                    analyticsClient.log(SettingsEvent.checkVersionsTapped)
                    
                case let ._somethingWentWrong(error):
                    analyticsClient.log(SettingsEvent.somethingWentWrong(error))
                }
                return .none
            }
        }
    }
}
