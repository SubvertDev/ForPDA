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

@Reducer
public struct AppDelegateFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    public struct State: Equatable {
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case didFinishLaunching(UIApplication)
        case didRegisterForRemoteNotifications(Data)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.notificationsClient) private var notificationsClient
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .didFinishLaunching:
                analyticsClient.configure()
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
