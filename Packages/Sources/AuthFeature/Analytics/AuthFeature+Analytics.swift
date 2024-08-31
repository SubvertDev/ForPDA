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
        
        var body: some ReducerOf<Self> {
            Reduce { state, action in
                switch action {
                case .binding, .onTask, .onSubmit, ._captchaResponse, ._loginResponse, .alert:
                    break
                    
                case .loginButtonTapped:
                    analyticsClient.log(AuthEvent.loginTapped)
                    
                case ._wrongPassword:
                    analyticsClient.log(AuthEvent.wrongPassword)
                    
                case ._wrongCaptcha:
                    analyticsClient.log(AuthEvent.wrongCaptcha)
                    
                case let .delegate(.loginSuccess(userId: userId)):
                    analyticsClient.log(AuthEvent.loginSuccess(userId))
                    analyticsClient.identify(String(userId))
                }
                return .none
            }
        }
    }
}
