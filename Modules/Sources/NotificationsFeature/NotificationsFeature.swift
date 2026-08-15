//
//  NotificationsSettingsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import ComposableArchitecture
import NotificationsClient
import PersistenceKeys
import Models
import CacheClient
import AnalyticsClient
import APIClient
import OSLog

@Reducer
public struct NotificationsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Presents public var logURL: URL?
        
        public var areNotificationsEnabled = false
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
        case favoritesModeChanged(NotificationsSettings2.FavoritesMode)
        case notificationOptionChanged(NotificationsSettings2, isEnabled: Bool)
        case onAppear
        
        case _onNotificationsPermissionResult(Result<Bool, any Error>)
    }
    
    // MARK: - Dependency
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.notificationsClient) private var notificationsClient
    @Dependency(\.logger[.notifications]) private var logger
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                return .none

            case let .favoritesModeChanged(mode):
                state.$appSettings.notifications2.withLock {
                    $0.favoritesMode = mode
                }
                return updateNotifications(settings: state.appSettings.notifications2)

            case let .notificationOptionChanged(option, isEnabled):
                state.$appSettings.notifications2.withLock { settings in
                    if isEnabled {
                        settings.insert(option)
                    } else {
                        settings.remove(option)
                    }
                }
                return updateNotifications(settings: state.appSettings.notifications2)

            case .onAppear:
                return .run { send in
                    let result = await Result { try await notificationsClient.requestPermission() }
                    await send(._onNotificationsPermissionResult(result))
                }
                
            case let ._onNotificationsPermissionResult(result):
                switch result {
                case let .success(isSuccess):
                    state.areNotificationsEnabled = isSuccess
                case let .failure(error):
                    // TODO: Log disabled?
                    print(error)
                    state.areNotificationsEnabled = false
                }
                return .none
            }
        }
    }

    private func updateNotifications(settings: NotificationsSettings2) -> Effect<Action> {
        return .run { _ in
            @Shared(.appStorage("device_token")) var deviceToken: String?
            if let deviceToken {
                let status = try await apiClient.notify(
                    token: deviceToken,
                    settings: settings,
                    isDebug: isDebug
                )
                logger.info("Push notifications updated with status `\(status)` and settings `\(settings.rawValue)`")
            }
            if let unread = cacheClient.getUnread() {
                await notificationsClient.showUnreadNotifications(unread)
            }
        }
    }
}

private var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}
