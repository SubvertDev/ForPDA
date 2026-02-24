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
        
        public var isQmsEnabled: Bool
        public var isForumEnabled: Bool
        public var isTopicsEnabled: Bool
        public var isForumMentionsEnabled: Bool
        public var isSiteMentionsEnabled: Bool
        public var isBackgroundNotificationsEnabled: Bool
        
        public init() {
            self.isQmsEnabled = _appSettings.notifications.isQmsEnabled.wrappedValue
            self.isForumEnabled = _appSettings.notifications.isForumEnabled.wrappedValue
            self.isTopicsEnabled = _appSettings.notifications.isTopicsEnabled.wrappedValue
            self.isForumMentionsEnabled = _appSettings.notifications.isForumMentionsEnabled.wrappedValue
            self.isSiteMentionsEnabled = _appSettings.notifications.isSiteMentionsEnabled.wrappedValue
            self.isBackgroundNotificationsEnabled = _appSettings.backgroundNotifications.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        case sendLogButtonTapped
        
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
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    let result = await Result { try await notificationsClient.requestPermission() }
                    await send(._onNotificationsPermissionResult(result))
                }
                
            case .sendLogButtonTapped:
                let data = cacheClient.getBackgroundTaskEntries()
                    .map { "[\($0.date.formatted(date: .numeric, time: .standard))] \($0.stage)"}
                    .joined(separator: "\n")
                    .data(using: .utf8)!
                
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("NotificationsLog-\(UUID().uuidString).txt")
                
                do {
                    try data.write(to: url, options: [.atomic])
                    state.logURL = url
                } catch {
                    analyticsClient.capture(error)
                }
                
                return .none
                
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
                
            case .binding(\.isQmsEnabled):
                state.$appSettings.notifications.isQmsEnabled.withLock { $0 = state.isQmsEnabled }
                return .none
                
            case .binding(\.isForumEnabled):
                state.$appSettings.notifications.isForumEnabled.withLock { $0 = state.isForumEnabled }
                return .none
                
            case .binding(\.isTopicsEnabled):
                state.$appSettings.notifications.isTopicsEnabled.withLock { $0 = state.isTopicsEnabled }
                return .none
                
            case .binding(\.isForumMentionsEnabled):
                state.$appSettings.notifications.isForumMentionsEnabled.withLock { $0 = state.isForumMentionsEnabled }
                return .none
                
            case .binding(\.isSiteMentionsEnabled):
                state.$appSettings.notifications.isSiteMentionsEnabled.withLock { $0 = state.isSiteMentionsEnabled }
                return .none
                
            case .binding(\.isBackgroundNotificationsEnabled):
                state.$appSettings.backgroundNotifications.withLock { $0 = state.isBackgroundNotificationsEnabled }
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
