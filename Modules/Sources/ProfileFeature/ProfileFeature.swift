//
//  ProfileFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import PersistenceKeys
import Models
import AnalyticsClient

@Reducer
public struct ProfileFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        @Shared(.userSession) public var userSession: UserSession?
        public let userId: Int?
        public var isLoading: Bool
        public var user: User?
        
        public var shouldShowToolbarButtons: Bool {
            return userSession != nil && user?.id == userSession?.userId
        }
        
        var didLoadOnce = false
        
        public init(
            alert: AlertState<Action.Alert>? = nil,
            userId: Int? = nil,
            isLoading: Bool = true,
            user: User? = nil
        ) {
            self.alert = alert
            self.userId = userId
            self.isLoading = isLoading
            self.user = user
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            case qmsButtonTapped
            case settingsButtonTapped
            case logoutButtonTapped
            case historyButtonTapped
            case deeplinkTapped(URL, ProfileDeeplinkType)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case userResponse(Result<User, any Error>)
        }
        
        case alert(Alert)
        public enum Alert: Equatable {
            case ok
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openQms
            case openSettings
            case openHistory
            case userLoggedOut
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                let userId = state.userId == nil ? state.userSession?.userId : state.userId
                guard let userId else { return .none }
                return .run { send in
                    for try await user in try await apiClient.getUser(userId, .cacheAndLoad) {
                        await send(.internal(.userResponse(.success(user))))
                    }
                } catch: { error, send in
                    await send(.internal(.userResponse(.failure(error))))
                }
                
            case .view(.historyButtonTapped):
                return .send(.delegate(.openHistory))
                
            case .view(.qmsButtonTapped):
                return .send(.delegate(.openQms))
                
            case .view(.settingsButtonTapped):
                return .send(.delegate(.openSettings))
                
            case .view(.deeplinkTapped(let url, _)):
                return .send(.delegate(.handleUrl(url)))
                
            case .view(.logoutButtonTapped):
                state.$userSession.withLock { $0 = nil }
                state.isLoading = true
                return .concatenate(
                    .run { send in
                        try await apiClient.logout()
                    },
                    .send(.delegate(.userLoggedOut))
                )
                
            case .internal(.userResponse(.success(let user))):
                state.isLoading = false
                state.user = user
                reportFullyDisplayed(&state)
                return .none
                
            case .internal(.userResponse(.failure(let error))):
                state.isLoading = false
                print(error, #line)
                reportFullyDisplayed(&state)
                return .none
                
            case .alert, .delegate:
                return .none
            }
        }
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
