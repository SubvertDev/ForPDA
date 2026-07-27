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
        case didReceiveNotification(UNNotification)
        case userNotification(String)
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
                
                // Stream should be created before .run so we don't miss any delegate calls
                let userNotificationsStream = notificationsClient.delegate()
                
                return .run { send in
                    await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await identifier in userNotificationsStream {
                                await send(.userNotification(identifier))
                            }
                        }
                        
                        group.addTask {
                            let granted = try await notificationsClient.requestPermission()
                            if granted {
                                logger.info("Notifications permission are granted")
                            } else {
                                logger.error("Notifications permission are not granted")
                            }
                            if granted { await notificationsClient.registerForRemoteNotifications() }
                        }
                        
                        group.addTask {
                            var properties: [String: Any] = [:]
                            
                            @Shared(.appSettings) var appSettings
                            let settingsProperties = appSettings.asDictionary()
                            let a11yProperties = await AccessibilityAnalytics.current(for: .current).asDictionary()
                            
                            properties.merge(settingsProperties) { old, new in new }
                            properties.merge(a11yProperties) { old, new in new }
                            
                            analyticsClient.setUserProperties(properties)
                        }
                    }
                }
                
            case let .didRegisterForRemoteNotifications(deviceToken):
                notificationsClient.setDeviceToken(deviceToken)
                return .run { [settings = state.appSettings.notifications, isDebug = isDebug] send in
                    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                    let status = try await apiClient.notify(token, settings, isDebug)
                    logger.info("Notifications initialized on server with status: \(status) and settings \(settings.rawValue)")
                }
                
            case let .didReceiveNotification(notification):
                guard let category = notification.request.content.userInfo["t"] as? Int,
                      let id = notification.request.content.userInfo["i"] as? Int,
                      let timestamp = notification.request.content.userInfo["v"] as? Int else {
                    return .send(.userNotification(notification.request.identifier))
                }
                return .send(.userNotification("\(category)-\(id)-\(timestamp)"))
                
            case .userNotification:
                // Handled in AppFeature instead
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
