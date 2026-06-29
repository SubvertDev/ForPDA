//
//  UserPunishmentFeature.swift
//  ForPDA
//
//  Created by Xialtal on 28.06.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct UserPunishmentFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let userId: Int
        public let target: UserPunishmentTarget
        
        var templates: [UserPunishmentCategory] = []
        var isLoading = false
        
        public init(
            userId: Int,
            target: UserPunishmentTarget
        ) {
            self.userId = userId
            self.target = target
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        
        case view(View)
        public enum View {
            case onAppear
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadTemplates(forId: Int)
            case templatesResponse(Result<[UserPunishmentCategory], any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case punishmentApplied
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                let forId = switch state.target {
                case .profile: 0
                case let .post(id): id
                case let .reputation(id): -id
                }
                return .send(.internal(.loadTemplates(forId: forId)))
                
            case let .internal(.loadTemplates(forId)):
                state.isLoading = true
                return .run { [userId = state.userId] send in
                    let response = try await apiClient.getUserPunishmentTemplates(forId, userId)
                    await send(.internal(.templatesResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.templatesResponse(.failure(error))))
                }
                
            case let .internal(.templatesResponse(.success(response))):
                state.templates = response
                state.isLoading = false
                return .none
                
            case let .internal(.templatesResponse(.failure(error))):
                print(error)
                state.isLoading = false
                return .none
                
            case .delegate, .binding:
                return .none
            }
        }
    }
}
