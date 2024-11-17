//
//  ProfileFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension ProfileFeature {
    
    struct Analytics: Reducer {
        typealias State = ProfileFeature.State
        typealias Action = ProfileFeature.Action
        
        @Dependency(\.analyticsClient) var analyticsClient
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .onTask, .alert:
                    break
                    
                case .qmsButtonTapped:
                    analyticsClient.log(ProfileEvent.qmsTapped)
                    
                case .settingsButtonTapped:
                    analyticsClient.log(ProfileEvent.settingsTapped)
                    
                case .logoutButtonTapped:
                    analyticsClient.log(ProfileEvent.logoutTapped)
                    analyticsClient.logout()
                    
                case .historyButtonTapped:
                    analyticsClient.log(ProfileEvent.historyTapped)
                    
                case let ._userResponse(.success(user)):
                    analyticsClient.log(ProfileEvent.userLoaded(user.id))
                    
                case ._userResponse(.failure):
                    analyticsClient.log(ProfileEvent.userLoadingFailed)
                }
                return .none
            }
        }
    }
}
