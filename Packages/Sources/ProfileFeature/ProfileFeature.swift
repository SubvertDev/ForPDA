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

@Reducer
public struct ProfileFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        @Shared(.userSession) public var userSession: UserSession?
        public let userId: Int?
        public var isLoading: Bool
        public var user: User?
        
        public var shouldShowLogoutButton: Bool {
            return userSession != nil
        }
        
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
    
    public enum Action {
        case onTask
        case logoutButtonTapped
        
        case _userResponse(Result<User, any Error>)
        
        case alert(Alert)
        public enum Alert: Equatable {
            case ok
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.dismiss) private var dismiss
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
                
            case .onTask:
                let userId = state.userId == nil ? state.userSession?.userId : state.userId
                guard let userId else { return .none }
                return .run { send in
                    do {
                        for try await user in try await apiClient.getUser(userId) {
                            await send(._userResponse(.success(user)))
                        }
                    } catch {
                        await send(._userResponse(.failure(error)))
                    }
                }
                
            case .logoutButtonTapped:
                state.userSession = nil
                state.isLoading = true
                return .none
                
            case ._userResponse(.success(let user)):
                state.isLoading = false
                state.user = user
                return .none
                
            case ._userResponse(.failure(let error)):
                state.isLoading = false
                print(error, #line)
                return .none
            }
        }
        
        Analytics()
    }
}
