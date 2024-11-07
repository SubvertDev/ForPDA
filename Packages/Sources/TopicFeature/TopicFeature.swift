//
//  ForumPageFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

public enum PageNavigationType {
    case first
    case previous
    case next
    case last
}

@Reducer
public struct TopicFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        let topicId: Int
        var topic: Topic?
        
        var offset: Int = 0
        let perPage: Int = 20
        
        var currentPage: Int {
            return offset / perPage + 1
        }
        
        var totalPages: Int {
            return topic == nil ? 0 : topic!.postsCount / 20 + 1
        }
        
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
        case pageNavigationTapped(PageNavigationType)
        
        case _loadTopic
        case _topicResponse(Result<Topic, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { [id = state.topicId, offset = state.offset, perPage = state.perPage] send in
                    let result = await Result { try await apiClient.getTopic(id: id, page: offset, perPage: perPage) }
                    await send(._topicResponse(result))
                }
                
            case let .pageNavigationTapped(type):
                switch type {
                case .first:
                    state.offset = 0
                case .previous:
                    state.offset -= state.perPage
                case .next:
                    state.offset += state.perPage
                case .last:
                    state.offset = state.topic!.postsCount - (state.topic!.postsCount % state.perPage)
                }
                // TODO: Remove later
                state.topic = nil
                return .run { [topicId = state.topicId, offset = state.offset, perPage = state.perPage] send in
                    let result = await Result { try await apiClient.getTopic(id: topicId, page: offset, perPage: perPage) }
                    await send(._topicResponse(result))
                }
                
            case ._loadTopic:
                return .none
                
            case let ._topicResponse(.success(topic)):
                customDump(topic)
                state.topic = topic
                return .none
                
            case let ._topicResponse(.failure(error)):
                print(error)
                return .none
            }
        }
        ._printChanges()
    }
}
