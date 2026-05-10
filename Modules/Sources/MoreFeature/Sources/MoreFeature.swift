//
//  MoreFeature.swift
//  MoreFeature
//
//  Created by Ilia Lubianoi on 02.05.2026.
//

import AnalyticsClient
import APIClient
import AuthFeature
import ComposableArchitecture
import Foundation
import Models
import NotificationsClient
import TCAExtensions

@Reducer
public struct MoreFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var auth: AuthFeature.State?
        @Shared(.userSession) var userSession: UserSession?
        
        var user: User?
        
        var qmsBadgeCount = 0
        var mentionsBadgeCount = 0
        
        var isLoading = false
        var isLoadingUser = false
        var didLoadOnce = false
        
        var isLoggedIn: Bool {
            return userSession != nil
        }
        
        public init() {}
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        public enum View {
            case onAppear
            
            case profileButtonTapped
            
//            case articlesButtonTapped
//            case favoritesButtonTapped
//            case forumButtonTapped
            case qmsButtonTapped
            case mentionsButtonTapped
            case historyButtonTapped
            
            case settingsButtonTapped
            
            case supportOnBoostyButtonTapped
            case appDiscussionButtonTapped
            case telegramChatButtonTapped
            case githubButtonTapped
            
            case logoutButtonTapped
        }
        case view(View)
        
        public enum Internal {
            case logoutResponse(Result<Void, any Error>)
            case userResponse(Result<User, any Error>)
            case updateBadgeCounts(Unread)
        }
        case `internal`(Internal)
        
        @CasePathable
        public enum Alert {
            case confirmLogout
        }
        case alert(PresentationAction<Alert>)
        case auth(PresentationAction<AuthFeature.Action>)
        
        public enum Delegate {
            case openProfile(Int, User)
//            case openArticles
//            case openFavorites
//            case openForum
            case openQms
            case openMentions
            case openHistory
            case openSettings
            case openDeeplink(URL)
        }
        case delegate(Delegate)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.notificationsClient) private var notificationsClient

    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                guard let userId = state.userSession?.userId else {
                    reportFullyDisplayed(&state)
                    return .none
                }
                return .merge(
                    getUser(&state),
//                    .run { send in
//                        for try await user in try await apiClient.getUser(userId: userId, policy: .cacheAndLoad) {
//                            await send(.internal(.userResponse(.success(user))))
//                        }
//                    } catch: { error, send in
//                        await send(.internal(.userResponse(.failure(error))))
//                    },
                    
                    .run { send in
                        let unread = try await apiClient.getUnread(type: .all)
                        await notificationsClient.showUnreadNotifications(unread, skipCategories: [])
                    },
                    
                    .run { send in
                        for await unread in notificationsClient.unreadPublisher().values {
                            await send(.internal(.updateBadgeCounts(unread)))
                        }
                    }
                )
                
            case .view(.profileButtonTapped):
                if state.isLoggedIn {
                    return .send(.delegate(.openProfile(state.userSession!.userId, state.user!)))
                } else {
                    state.auth = AuthFeature.State()
                    return .none
                }
                
            case .view(.qmsButtonTapped):
                return .send(.delegate(.openQms))
                
            case .view(.mentionsButtonTapped):
                return .send(.delegate(.openMentions))
                
            case .view(.historyButtonTapped):
                return .send(.delegate(.openHistory))
                
            case .view(.settingsButtonTapped):
                return .send(.delegate(.openSettings))
                
            case .view(.supportOnBoostyButtonTapped):
                return .run { _ in
                    await open(url: Links.boosty)
                }
                
            case .view(.appDiscussionButtonTapped):
                return .send(.delegate(.openDeeplink(Links.appDiscussion)))
                
            case .view(.telegramChatButtonTapped):
                return .run { _ in
                    await open(url: Links.telegramChat)
                }
                
            case .view(.githubButtonTapped):
                return .run { _ in
                    await open(url: Links.github)
                }
                
            case .view(.logoutButtonTapped):
                state.alert = .logoutWarning
                return .none
                
            case let .internal(.logoutResponse(response)):
                state.isLoading = false
                state.$userSession.withLock { $0 = nil }
                analyticsClient.logout()
                if case let .failure(error) = response {
                    analyticsClient.capture(error)
                }
                return .none
                
            case let .internal(.userResponse(.success(user))):
                state.isLoadingUser = false
                state.user = user
                reportFullyDisplayed(&state)
                return .none
                
            case let .internal(.userResponse(.failure(error))):
                print(error)
                state.isLoadingUser = false
                reportFullyDisplayed(&state)
                return .none
                
            case let .internal(.updateBadgeCounts(unread)):
                state.qmsBadgeCount = unread.qmsUnreadCount
                state.mentionsBadgeCount = unread.mentionsUnreadCount
                return .none
                
            case .alert(.presented(.confirmLogout)):
                state.isLoading = true
                return .run { send in
                    try await apiClient.logout()
                    await send(.internal(.logoutResponse(.success(()))))
                } catch: { error, send in
                    await send(.internal(.logoutResponse(.failure(error))))
                }
                
            case .auth(.presented(.delegate(.loginSuccess(userId: _)))):
                state.auth = nil
                return getUser(&state)
                
            case .alert, .auth, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$auth, action: \.auth) {
            AuthFeature()
        }
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
    
    private func getUser(_ state: inout State) -> Effect<Action> {
        if state.user == nil {
            state.isLoadingUser = true
        }
        return .run { [userId = state.userSession!.userId] send in
            for try await user in try await apiClient.getUser(userId: userId, policy: .cacheAndLoad) {
                await send(.internal(.userResponse(.success(user))))
            }
        } catch: { error, send in
            await send(.internal(.userResponse(.failure(error))))
        }
    }
}

// MARK: - Alert Extensions

private extension AlertState where Action == MoreFeature.Action.Alert {
    nonisolated(unsafe) static let logoutWarning = Self {
        TextState("Are you sure you want to log out of your profile?", bundle: .module)
    } actions: {
        ButtonState(role: .destructive, action: .confirmLogout) {
            TextState("Logout", bundle: .module)
        }
        ButtonState(role: .cancel) {
            TextState("Cancel", bundle: .module)
        }
    }
}
