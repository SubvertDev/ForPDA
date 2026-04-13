//
//  PostKarmaHistoryFeature.swift
//  ForPDA
//
//  Created by Xialtal on 10.04.26.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct PostKarmaHistoryFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public let postId: Int
        
        var history: [PostKarmaVote] = []
        var isLoading = false
        
        public init(postId: Int) {
            self.postId = postId
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            
            case cancelButtonTapped
            case userButtonTapped(Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case loadKarmaHistory
            case karmaHistoryResponse(Result<[PostKarmaVote], any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openUser(Int)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.dismiss) var dismiss
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadKarmaHistory))
                
            case .view(.cancelButtonTapped):
                return .run { _ in await dismiss() }
                
            case let .view(.userButtonTapped(id)):
                return .send(.delegate(.openUser(id)))
                
            case .internal(.loadKarmaHistory):
                state.isLoading = false
                return .run { [postId = state.postId] send in
                    let response = try await apiClient.postKarmaHistory(postId: postId)
                    await send(.internal(.karmaHistoryResponse(.success(response))))
                } catch: { error, send in
                    await send(.internal(.karmaHistoryResponse(.failure(error))))
                }
                
            case let .internal(.karmaHistoryResponse(.success(response))):
                state.history = response
                state.isLoading = false
                return .none
                
            case let .internal(.karmaHistoryResponse(.failure(error))):
                print(error)
                state.isLoading = false
                return .run { _ in await dismiss() }
                
            case .delegate:
                return .none
            }
        }
    }
}
