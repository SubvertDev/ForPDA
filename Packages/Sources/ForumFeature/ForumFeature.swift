//
//  ForumFeature.swift
//  ForPDA
//
//  Created by Xialtal on 25.10.24.
//

import Foundation
import ComposableArchitecture
import PageNavigationFeature
import APIClient
import Models
import PersistenceKeys

@Reducer
public struct ForumFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings

        public var forumId: Int
        public var forumName: String
        
        public var forum: Forum?
        public var topics: [TopicInfo] = []
        public var topicsPinned: [TopicInfo] = []
        
        public var isLoadingTopics = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .forum)
        
        public init(
            forumId: Int,
            forumName: String
        ) {
            self.forumId = forumId
            self.forumName = forumName
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case settingsButtonTapped
        case topicTapped(id: Int)
        case subforumTapped(id: Int, name: String)
        
        case pageNavigation(PageNavigationFeature.Action)
        
        case _loadForum(offset: Int)
        case _forumResponse(Result<Forum, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .onTask:
                return .send(._loadForum(offset: 0))
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(._loadForum(offset: newOffset))
                
            case .pageNavigation:
                return .none
                
            case let ._loadForum(offset):
                state.isLoadingTopics = true
                return .run { [id = state.forumId, perPage = state.appSettings.forumPerPage] send in
                    let result = await Result { try await apiClient.getForum(id: id, page: offset, perPage: perPage) }
                    await send(._forumResponse(result))
                }
                
            case .settingsButtonTapped:
                return .none
                
            case .topicTapped:
                return .none
            
            case .subforumTapped:
                return .none
                
            case let ._forumResponse(.success(forum)):
                var topics: [TopicInfo] = []
                var pinnedTopics: [TopicInfo] = []
                
                for topic in forum.topics {
                    if topic.isPinned {
                        pinnedTopics.append(topic)
                    } else {
                        topics.append(topic)
                    }
                }
                
                state.forum = forum
                state.topics = topics
                
                if !pinnedTopics.isEmpty {
                    state.topicsPinned = pinnedTopics
                }
                
                // TODO: Is it ok?
                state.pageNavigation.count = forum.topicsCount
                
                state.isLoadingTopics = false
                
                return .none
                
            case let ._forumResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}
