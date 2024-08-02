//
//  ProfileFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct ProfileFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Presents public var alert: AlertState<Action.Alert>?
        public let userId: Int
        public var isLoading: Bool
        public var user: User?
        
        public init(
            userId: Int,
            isLoading: Bool = true,
            user: User? = nil
        ) {
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
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alert:
                return .none
                
            case .onTask:
                return .run { [userId = state.userId] send in
                    do {
                        let user = try await apiClient.getUser(userId: userId)
                        await send(._userResponse(.success(user)))
                    } catch {
                        await send(._userResponse(.failure(error)))
                    }
                }
                
            case .logoutButtonTapped:
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
    }
}
