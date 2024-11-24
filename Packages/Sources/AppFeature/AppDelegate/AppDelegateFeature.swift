//
//  AppDelegateFeature.swift
//
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import UIKit
import ComposableArchitecture
import AnalyticsClient
import LoggerClient
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
        @Shared(.appStorage(ParserSettings.key)) var parserVersion: Int = 1
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
    @Dependency(\.logger[.app]) private var logger
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .didFinishLaunching:
                analyticsClient.configure(
                    isDebug
                    ? state.appSettings.analyticsConfigurationDebug
                    : state.appSettings.analyticsConfigurationRelease
                )
                
                cacheClient.configure()
                
                return .run { [parserVersion = state.$parserVersion] send in
                    if ParserSettings.version > parserVersion.wrappedValue {
                        logger.warning("Parser version outdated, removing posts cache")
                        await cacheClient.removeAllParsedPostContent()
                        await parserVersion.withLock { $0 = ParserSettings.version }
                    } else {
                        logger.info("Parser version match (\(parserVersion.wrappedValue))")
                    }
                    
                    let granted = try await notificationsClient.requestPermission()
                    if granted {
                        logger.info("Notifications permission are granted")
                    } else {
                        logger.error("Notifications permission are not granted")
                    }
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
