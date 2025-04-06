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
                // TODO: Move to analytics client instead?
                if state.appSettings.analyticsConfigurationDebug != AnalyticsConfiguration.debug {
                    state.$appSettings.analyticsConfigurationDebug.withLock { $0 = AnalyticsConfiguration.debug }
                }
                if state.appSettings.analyticsConfigurationRelease != AnalyticsConfiguration.release {
                    state.$appSettings.analyticsConfigurationRelease.withLock { $0 = AnalyticsConfiguration.release }
                }
                
                analyticsClient.configure(
                    isDebug
                    ? state.appSettings.analyticsConfigurationDebug
                    : state.appSettings.analyticsConfigurationRelease
                )
                
                cacheClient.configure()
                
                return .run { send in
                    await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await _ in notificationsClient.delegate() {
                                print("test")
                            }
                        }
                        
                        group.addTask {
                            let granted = try await notificationsClient.requestPermission()
                            if granted {
                                logger.info("Notifications permission are granted")
                            } else {
                                logger.error("Notifications permission are not granted")
                            }
                            //if granted { await application.registerForRemoteNotifications() }
                        }
                    }
                }
                
            case let .didRegisterForRemoteNotifications(deviceToken):
                notificationsClient.setDeviceToken(deviceToken)
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
