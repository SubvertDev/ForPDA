//
//  MenuFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import PersistenceKeys
import TCAExtensions
import Models

@Reducer
public struct MenuFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Never>?
        @Shared(.userSession) public var userSession: UserSession?
        public var user: User?
        public var isLoadingUser = false
        
        public init(
            alert: AlertState<Never>? = nil,
            userSession: UserSession? = nil,
            user: User? = nil,
            isLoadingUser: Bool = false
        ) {
            self.alert = alert
            self._userSession = Shared(wrappedValue: userSession, .userSession)
            self.user = user
            self.isLoadingUser = isLoadingUser
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case alert(PresentationAction<Never>)
        case notImplementedFeatureTapped
        case profileTapped
        case settingsTapped
        case telegramChangelogButtonTapped
        case telegramChatButtonTapped
        case githubButtonTapped
        
        case _subscribeToUpdates
        case _userSessionUpdated(UserSession?)
        case _loadUserResult(Result<User, any Error>)
        
        case delegate(Delegate)
        public enum Delegate {
            case openAuth
            case openProfile(id: Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    
    // MARK: - Cancellable
    
    private enum CancelID {
        case userLoading
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                // TODO: Is this ok?
                if state.userSession != nil && state.user == nil {
                    return .merge([
                        .run { send in
                            await send(._subscribeToUpdates)
                        },
                        .run { [userSession = state.userSession] send in
                            await send(._userSessionUpdated(userSession))
                        }
                    ])
                } else {
                    return .run { send in
                        await send(._subscribeToUpdates)
                    }
                }

                
            case ._subscribeToUpdates:
                return .publisher {
                    state.$userSession.publisher
                        .map(Action._userSessionUpdated)
                }
                
            case .alert, .delegate:
                return .none
                
            case .notImplementedFeatureTapped:
                state.alert = .notImplemented
                return .none
                
            case .profileTapped:
                return .run { [userSession = state.userSession] send in
                    if let userSession {
                        await send(.delegate(.openProfile(id: userSession.userId)))
                    } else {
                        await send(.delegate(.openAuth))
                    }
                }
                
            case .settingsTapped:
                return .none
                
            case .telegramChangelogButtonTapped:
                return .run { _ in
                    await open(url: Links.telegramChangelog)
                }
                
            case .telegramChatButtonTapped:
                return .run { _ in
                    await open(url: Links.telegramChat)
                }
                
            case .githubButtonTapped:
                return .run { _ in
                    await open(url: Links.github)
                }
                
            case let ._userSessionUpdated(userSession):
                // TODO: Refactor?
                if let userSession {
                    return .run { send in
                        if let user = await cacheClient.getUser(userSession.userId) {
                            await send(._loadUserResult(.success(user)))
                        } else {
                            do {
                                for try await user in try await apiClient.getUser(userId: userSession.userId) {
                                    await send(._loadUserResult(.success(user)))
                                }
                            } catch {
                                await send(._loadUserResult(.failure(error)))
                            }
                        }
                    }
                    .cancellable(id: CancelID.userLoading)
                } else {
                    state.user = nil
                    return .none
                }
                 
            case let ._loadUserResult(result):
                switch result {
                case .success(let user):
                    state.user = user
                    
                case .failure(_):
                    // TODO: Handle in analytics
                    state.user = nil
                    state.alert = .somethingWentWrong
                }
                return .cancel(id: CancelID.userLoading)
            }
        }
        .ifLet(\.alert, action: \.alert)
        
        Analytics()
    }
}
