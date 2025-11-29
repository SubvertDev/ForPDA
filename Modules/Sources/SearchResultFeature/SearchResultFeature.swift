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
        var content: [UIContent] = []
        
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
            case buildContent([SearchContent])
            case searchResponse(Result<SearchResponse, any Error>)
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
                } catch: { error, send in
                    await send(.internal(.searchResponse(.failure(error))))
                }
                
            case let .internal(.searchResponse(.success(response))):
                state.contentCount = response.contentCount
                return .send(.internal(.buildContent(response.content)))
                
            case let .internal(.buildContent(content)):
                for type in content {
                    switch type {
                    case .post(let post):
                        let topicTypes = TopicNodeBuilder(text: post.post.content, attachments: post.post.attachments).build()
                        let uiPost = UIPost(post: post.post, content: topicTypes.map { .init(value: $0) } )
                        state.content.append(.post(.init(topicId: post.topicId, topicName: post.topicName, post: uiPost)))
                    case .topic(let topic):
                        state.content.append(.topic(topic))
                    case .article(let article):
                        state.content.append(.article(article))
                    }
                }
                state.isLoading = false
                return .none
                
            case let .internal(.searchResponse(.failure(error))):
                print(error)
                // TODO: Toast.
                return .none
            }
        }
    }
}
