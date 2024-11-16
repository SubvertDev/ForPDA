//
//  AppDelegateFeature.swift
//
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import UIKit
import ComposableArchitecture
import AnalyticsClient
import CacheClient
import NotificationsClient
import PersistenceKeys
import Models

@Reducer
public struct AppDelegateFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case didFinishLaunching(UIApplication)
        case didRegisterForRemoteNotifications(Data)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.notificationsClient) private var notificationsClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .didFinishLaunching:
                analyticsClient.configure(
                    isDebug
                    ? state.appSettings.analyticsConfigurationDebug
                    : state.appSettings.analyticsConfigurationRelease
                )
                
                cacheClient.configure()
                
                return .run { send in
                    let granted = try await notificationsClient.requestPermission()
                    print("Notifications permission are granted: \(granted)")
                    //if granted { await application.registerForRemoteNotifications() }
                }
                
            case let .didRegisterForRemoteNotifications(deviceToken):
                notificationsClient.setDeviceToken(deviceToken)
                notificationsClient.setNotificationsDelegate()
                return .none
            }
        }
    }
}

// MARK: - Helpers

private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}
