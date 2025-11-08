//
//  AuthFeature+Analytics.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

extension AuthFeature {
    
    struct Analytics: Reducer {
        typealias State = AuthFeature.State
        typealias Action = AuthFeature.Action
        
        @Dependency(\.analyticsClient) var analyticsClient
        
        var body: some Reducer<State, Action> {
            Reduce<State, Action> { state, action in
                switch action {
                case .binding,
                        .alert,
                        .view(.onAppear),
                        .view(.onSubmit),
                        .view(.closeButtonTapped),
                        .view(.settingsButtonTapped),
                        .internal(.captchaResponse),
                        .internal(.loginResponse):
                    break
                    
                case .view(.loginButtonTapped):
                    analyticsClient.log(AuthEvent.loginTapped)
                    
                case .internal(.wrongPassword):
                    analyticsClient.log(AuthEvent.wrongPassword)
                    
                case .internal(.wrongCaptcha):
                    analyticsClient.log(AuthEvent.wrongCaptcha)
                    
                case let .internal(.somethingWentWrong(id)):
                    analyticsClient.log(AuthEvent.somethingWentWrong(id: id))
                    analyticsClient.capture(NSError(domain: "Auth unknown response", code: id))
                    
                case let .delegate(.loginSuccess(reason, userId)):
                    analyticsClient.log(AuthEvent.loginSuccess(reason: reason.rawValue, userId: userId))
                    analyticsClient.identify(String(userId))
                    
                case .delegate(.showSettings):
                    break
                }
                return .none
            }
        }
    }
}
