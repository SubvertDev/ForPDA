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

@Reducer
public struct NotificationsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Presents public var logURL: URL?
        
        public var areNotificationsEnabled = false
        
        var favoritesSettings: FavoritesNotificationSettings = .no
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        
        case binding(BindingAction<State>)
        
        case _onNotificationsPermissionResult(Result<Bool, any Error>)
    }
    
    // MARK: - Dependency
    
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.notificationsClient) private var notificationsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
            .onChange(of: \.favoritesSettings) { _, state in
                state.$appSettings.notifications.withLock { settings in
                    switch state.favoritesSettings {
                    case .all:
                        settings.remove(.favoritesImportant)
                        settings.insert(.favorites)
                    case .important:
                        settings.remove(.favorites)
                        settings.insert(.favoritesImportant)
                    case .no:
                        settings.remove([.favorites, .favoritesImportant])
                    }
                }
                return .none
            }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                state.favoritesSettings = if state.appSettings.notifications.contains(.favorites) {
                    .all
                } else if state.appSettings.notifications.contains(.favoritesImportant) {
                    .important
                } else {
                    .no
                }
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
                
            case .binding:
                return .run { _ in
                    if let unread = cacheClient.getUnread() {
                        await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
                    }
                }
            }
        }
    }
}
