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

@Reducer
public struct NotificationsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        public var areNotificationsEnabled = false
        
        public var isQmsEnabled: Bool
        public var isForumEnabled: Bool
        public var isTopicsEnabled: Bool
        public var isForumMentionsEnabled: Bool
        public var isSiteMentionsEnabled: Bool
        
        public init() {
            self.isQmsEnabled = _appSettings.notifications.isQmsEnabled.wrappedValue
            self.isForumEnabled = _appSettings.notifications.isForumEnabled.wrappedValue
            self.isTopicsEnabled = _appSettings.notifications.isTopicsEnabled.wrappedValue
            self.isForumMentionsEnabled = _appSettings.notifications.isForumMentionsEnabled.wrappedValue
            self.isSiteMentionsEnabled = _appSettings.notifications.isSiteMentionsEnabled.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        
        case binding(BindingAction<State>)
        
        case _onNotificationsPermissionResult(Result<Bool, any Error>)
    }
    
    // MARK: - Dependency
    
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
                state.appSettings.notifications.isQmsEnabled = state.isQmsEnabled
                return .none
                
            case .binding(\.isForumEnabled):
                state.appSettings.notifications.isForumEnabled = state.isForumEnabled
                return .none
                
            case .binding(\.isTopicsEnabled):
                state.appSettings.notifications.isTopicsEnabled = state.isTopicsEnabled
                return .none
                
            case .binding(\.isForumMentionsEnabled):
                state.appSettings.notifications.isForumMentionsEnabled = state.isForumMentionsEnabled
                return .none
                
            case .binding(\.isSiteMentionsEnabled):
                state.appSettings.notifications.isSiteMentionsEnabled = state.isSiteMentionsEnabled
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
