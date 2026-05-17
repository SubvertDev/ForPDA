//
//  NavigationSettingsFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import ComposableArchitecture
import PersistenceKeys
import Models
import CacheClient

@Reducer
public struct NavigationSettingsFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        var userSessionGroup: User.Group?
        
        public var topicOpening: TopicOpeningStrategy
        public var topicShowAllPosts: Bool
        public var hideTabBarOnScroll: Bool
        public var floatingNavigation: Bool
        public var experimentalFloatingNavigation: Bool
        
        var isUserSessionHasModerationGroup: Bool {
            return userSessionGroup == .admin
                || userSessionGroup == .supermoderator
                || userSessionGroup == .moderator
                || userSessionGroup == .moderatorHelper
                || userSessionGroup == .moderatorSchool
        }

        public init() {
            self.topicOpening = _appSettings.topicOpeningStrategy.wrappedValue
            self.hideTabBarOnScroll = _appSettings.hideTabBarOnScroll.wrappedValue
            self.floatingNavigation = _appSettings.floatingNavigation.wrappedValue
            self.experimentalFloatingNavigation = _appSettings.experimentalFloatingNavigation.wrappedValue
            self.topicShowAllPosts = _appSettings.topicShowAllPostsFilter.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
        }
        
        case `internal`(Internal)
        public enum Internal {
            case initUserSessionGroup(User.Group)
        }
    }
    
    // MARK: - Dependency
    
    @Dependency(\.cacheClient) private var cacheClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .run { [session = state.userSession] send in
                    if let session, let user = cacheClient.getUser(session.userId) {
                        await send(.internal(.initUserSessionGroup(user.group)))
                    }
                }
                
            case .binding(\.topicOpening):
                state.$appSettings.topicOpeningStrategy.withLock { $0 = state.topicOpening }
                
            case .binding(\.topicShowAllPosts):
                state.$appSettings.topicShowAllPostsFilter.withLock { $0 = state.topicShowAllPosts }
                
            case .binding(\.hideTabBarOnScroll):
                state.$appSettings.hideTabBarOnScroll.withLock { $0 = state.hideTabBarOnScroll }
                
            case .binding(\.floatingNavigation):
                state.$appSettings.floatingNavigation.withLock { $0 = state.floatingNavigation }
                if !state.appSettings.floatingNavigation {
                    state.$appSettings.experimentalFloatingNavigation.withLock { $0 = false }
                    state.experimentalFloatingNavigation = false
                }

            case .binding(\.experimentalFloatingNavigation):
                guard state.floatingNavigation else { return .none }
                state.$appSettings.experimentalFloatingNavigation.withLock { $0 = state.experimentalFloatingNavigation }
                
            case .binding:
                break
                
            case let .internal(.initUserSessionGroup(group)):
                state.userSessionGroup = group
                return .none
            }
            
            return .none
        }
    }
}
