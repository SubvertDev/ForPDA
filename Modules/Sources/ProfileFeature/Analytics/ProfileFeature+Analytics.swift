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
                case .view(.onAppear), .delegate, .binding, .destination:
                    break
                    
                case .view(.sheetContinueButtonTapped):
                    analyticsClient.log(ProfileEvent.sheetContinueButtonTapped)
                    
                case .view(.sheetCloseButtonTapped):
                    analyticsClient.log(ProfileEvent.sheetCloseButtonTapped)
                    
                case .view(.qmsButtonTapped):
                    analyticsClient.log(ProfileEvent.qmsTapped)
                    
                case .view(.settingsButtonTapped):
                    analyticsClient.log(ProfileEvent.settingsTapped)
                    
                case .view(.logoutButtonTapped):
                    analyticsClient.log(ProfileEvent.logoutTapped)
                    analyticsClient.logout()
                    
                case .view(.historyButtonTapped):
                    analyticsClient.log(ProfileEvent.historyTapped)
                    
                case .view(.reputationButtonTapped):
                    analyticsClient.log(ProfileEvent.reputationTapped)
                    
                case .view(.deeplinkTapped(_, let type)):
                    switch type {
                    case .about:
                        analyticsClient.log(ProfileEvent.linkInAboutTapped)
                    case .signature:
                        analyticsClient.log(ProfileEvent.linkInSignatureTapped)
                    case .achievement:
                        analyticsClient.log(ProfileEvent.achievementTapped)
                    }
                    
                case .internal(.userResponse(.success(let user))):
                    analyticsClient.log(ProfileEvent.userLoaded(user.id))
                    
                case .internal(.userResponse(.failure)):
                    analyticsClient.log(ProfileEvent.userLoadingFailed)
                }
                return .none
            }
        }
    }
}
