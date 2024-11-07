//
//  ForumFeature.swift
//  ForPDA
//
//  Created by Xialtal on 25.10.24.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct ForumFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var forumId: Int?
        public var forumName: String?
        public var forum: Forum?
        public var topics: [TopicInfo] = []
        public var topicsPinned: [TopicInfo] = []
        
        public init(
            forumId: Int? = nil,
            forumName: String? = nil,
            forum: Forum? = nil,
            topics: [TopicInfo] = [],
            topicsPinned: [TopicInfo] = []
        ) {
            self.forumId = forumId
            self.forumName = forumName
            self.forum = forum
            self.topics = topics
            self.topicsPinned = topicsPinned
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case settingsButtonTapped
        case topicTapped(id: Int)
        case subforumTapped(id: Int, name: String)
        
        case _forumResponse(Result<Forum, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { [forumId = state.forumId] send in
                    guard let forumId else { return }
                        // TODO: Implement normal pagination.
                        let result = await Result { try await apiClient.getForum(id: forumId, page: 0, perPage: 10) }
                        
                        await send(._forumResponse(result))
                }
                
            case .topicTapped(let id):
                return .none
            
            case .subforumTapped(let id, let name):
                return .none
                
            case .settingsButtonTapped:
                return .none
                
            case let ._forumResponse(.success(forum)):
                var topics: [TopicInfo] = []
                var pinnedTopics: [TopicInfo] = []
                
                for topic in forum.topics {
                    // TODO: Think about more good method for checking.
                    if topic.flag == 97 { // is pinned
                        pinnedTopics.append(topic)
                    } else { topics.append(topic) }
                }
                
                state.forum = forum
                state.topics = topics
                state.topicsPinned = pinnedTopics
                return .none
                
            case let ._forumResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}
