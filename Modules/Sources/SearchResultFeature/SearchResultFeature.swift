//
//  SearchResultFeature.swift
//  ForPDA
//
//  Created by Xialtal on 26.11.25.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models
import PersistenceKeys
import SharedUI
import TopicBuilder

@Reducer
public struct SearchResultFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.userSession) var userSession: UserSession?
        
        public let request: SearchRequest
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var contentCount = 0
        var content: [SearchContent] = []
        
        var isLoading = false
        
        public init(
            request: SearchRequest
        ) {
            self.request = request
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            
            case postTapped
            case topicTapped
            case articleTapped
        }
        
        case `internal`(Internal)
        public enum `Internal` {
            case loadContent
            case searchResponse(Result<SearchResponse, any Error>)
            case loadPostTypes([UITopicType])
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                return .send(.internal(.loadContent))
                
            case .view(.postTapped):
                return .none
                
            case .view(.topicTapped):
                return .none
                
            case .view(.articleTapped):
                return .none
                
            case .internal(.loadContent):
                state.isLoading = true
                return .run { [request = state.request] send in
                    let respone = try await apiClient.search(request: request)
                    await send(.internal(.searchResponse(.success(respone))))
                }
                
            case .internal(.loadPostTypes(let types)):
                return .none
                
            case let .internal(.searchResponse(.success(response))):
                state.content = response.content
                state.contentCount = response.contentCount
                
                state.isLoading = false
                return .none
                
            case let .internal(.searchResponse(.failure(error))):
                print(error)
                return .none
            }
        }
    }
}
