//
//  ForumPageFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import Foundation
import ComposableArchitecture
import PageNavigationFeature
import APIClient
import Models
import PersistenceKeys
import ParsingClient

@Reducer
public struct TopicFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings

        let topicId: Int
        var topic: Topic?
        
        var types: [[TopicType]] = []
        
        var isFirstPage = true
        var isLoadingTopic = true
        
        var pageNavigation = PageNavigationFeature.State(type: .topic)
        
        public init(
            topicId: Int,
            topic: Topic? = nil
        ) {
            self.topicId = topicId
            self.topic = topic
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case pageNavigation(PageNavigationFeature.Action)
        
        case _loadTopic(offset: Int)
        case _loadTypes([[TopicType]])
        case _topicResponse(Result<Topic, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    
    // MARK: - Cancellable
    
    private enum CancelID { case loading }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                return .send(._loadTopic(offset: 0))

            case let .pageNavigation(.offsetChanged(to: newOffset)):
                state.isFirstPage = newOffset == 0
                return .concatenate([
                    .cancel(id: CancelID.loading),
                    .send(._loadTopic(offset: newOffset))
                ])
                
            case .pageNavigation:
                return .none
                
            case let ._loadTopic(offset):
                state.isLoadingTopic = true
                return .run { [id = state.topicId, perPage = state.appSettings.topicPerPage] send in
                    let result = await Result { try await apiClient.getTopic(id: id, page: offset, perPage: perPage) }
                    await send(._topicResponse(result))
                }
                .cancellable(id: CancelID.loading)
                
            case let ._topicResponse(.success(topic)):
//                customDump(topic)
                state.topic = topic
                
                // TODO: Is it ok?
                state.pageNavigation.count = topic.postsCount
                
                return .run { send in
                    var topicTypes: [[TopicType]] = []
                    for post in topic.posts {
                        if let content = await cacheClient.getParsedPostContent(post.id) {
                            let types = try! TopicBuilder.build(from: content)
                            topicTypes.append(types)
                        } else {
                            let parsedContent = BBCodeParser.parse(post.content)!
                            await cacheClient.cacheParsedPostContent(post.id, parsedContent)
                            let types = try! TopicBuilder.build(from: parsedContent)
                            topicTypes.append(types)
                        }
                    }
                    
                    await send(._loadTypes(topicTypes))
                }
                .cancellable(id: CancelID.loading)
                
            case let ._loadTypes(types):
                state.types = types
                state.isLoadingTopic = false
                return .none
                
            case let ._topicResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}
