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
        
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .destination:
                    break
                    
                case .languageButtonTapped:
                    analyticsClient.log(SettingsEvent.languageTapped)
                    
                case .themeButtonTapped:
                    analyticsClient.log(SettingsEvent.themeTapped)
                    
                case .safariExtensionButtonTapped:
                    analyticsClient.log(SettingsEvent.safariExtensionTapped)
                    
                case .copyDebugIdButtonTapped:
                    analyticsClient.log(SettingsEvent.copyDebugIdTapped)

                case .clearCacheButtonTapped:
                    analyticsClient.log(SettingsEvent.clearCacheTapped)

                case .checkVersionsButtonTapped:
                    analyticsClient.log(SettingsEvent.checkVersionsTapped)

                case let ._somethingWentWrong(error):
                    analyticsClient.log(SettingsEvent._somethingWentWrong(error))
                }
                return .none
            }
        }
    }
}
