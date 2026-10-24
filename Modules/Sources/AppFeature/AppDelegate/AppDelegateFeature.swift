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
import APIClient
import OSLog

@Reducer
public struct AppDelegateFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action {
        case didFinishLaunching(UIApplication)
        case didRegisterForRemoteNotifications(Data)
        case didFailToRegisterForRemoteNotificationsWithError(Error)
        case didReceiveNotification(UNNotificationSnapshot)
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
                
                let deliveryMethod = state.appSettings.notificationsDeliveryMethod
                
                return .run { [isLoggedIn = state.userSession != nil] send in
                    await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            for await notification in userNotificationsStream {
                                await send(.didReceiveNotification(notification))
                            }
                        }
                        
                        group.addTask {
                            let granted = try await notificationsClient.requestPermission()
                            if granted {
                                logger.info("Notifications permission is granted")
                            } else {
                                logger.error("Notifications permission is not granted")
                            }
                            
                            switch deliveryMethod {
                            case .push:
                                await notificationsClient.registerForRemoteNotifications()
                            case .background:
                                await notificationsClient.unregisterForRemoteNotifications()
                                guard isLoggedIn else { return }
                                @Shared(.appStorage(AppStorageKeys.deviceToken)) var deviceToken: String?
                                if let deviceToken {
                                    let status = try await apiClient.notify(token: deviceToken, settings: .disabled, isDebug: isDebug)
                                    logger.info("Push notifications initialized with status `\(status)` and disabled settings")
                                }
                            }
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
                
            case let .didRegisterForRemoteNotifications(deviceTokenData):
                let token = deviceTokenData.map { String(format: "%02.2hhx", $0) }.joined()
                
                @Shared(.appStorage(AppStorageKeys.deviceToken)) var deviceToken: String?
                $deviceToken.withLock { $0 = token }
                
                analyticsClient.registerPushNotificationToken(token)
                
                guard state.userSession != nil else { return .none }
                return .run { [settings = state.appSettings.notifications2] send in
                    let status = try await apiClient.notify(token, settings, isDebug)
                    logger.info("Push notifications initialized with status `\(status)` and settings `\(settings.rawValue)`")
                }
                
            case let .didFailToRegisterForRemoteNotificationsWithError(error):
                logger.error("\(error.localizedDescription, privacy: .public)")
                return .none
                
            case let .didReceiveNotification(notification):
                let identifier = notification.pdaIdentifier?.rawValue ?? notification.identifier
                return .send(.userNotification(identifier))
                
            case .userNotification:
                // Handled in AppFeature instead
                return .none
            }
        }
    }
}
