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
                case .binding, .onTask, .onSubmit, ._captchaResponse, ._loginResponse, .alert, .cancelButtonTapped:
                    break
                    
                case .loginButtonTapped:
                    analyticsClient.log(AuthEvent.loginTapped)
                    
                case ._wrongPassword:
                    analyticsClient.log(AuthEvent.wrongPassword)
                    
                case ._wrongCaptcha:
                    analyticsClient.log(AuthEvent.wrongCaptcha)
                    
                case let .delegate(.loginSuccess(reason, userId)):
                    analyticsClient.log(AuthEvent.loginSuccess(reason: reason.rawValue, userId: userId))
                    analyticsClient.identify(String(userId))
                }
                return .none
            }
        }
    }
}
