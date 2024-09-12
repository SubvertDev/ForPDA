//
//  File.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
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
        public var sections: [ForumSection] = []
//        public var topics: [ForumTopic] = []
        
        public init(
            sections: [ForumSection] = []
//            topics: [ForumTopic] = []
        ) {
            self.sections = sections
//            self.topics = topics
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case topicTapped(id: Int)
//        case _forumTopicsResponse(Result<[ForumTopic], any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { send in
//                    let result = await Result { try await apiClient.getForumTopics() }
//                    await send(._forumTopicsResponse(result))
                }
                
            case let .topicTapped(id: id):
                return .run { send in
//                    let result = await Result { try await apiClient.getForumTopic(id: id, page: 0, itemsPerPage: 10) }
                }
                
//            case let ._forumTopicsResponse(.success(topics)):
//                var sections: [ForumSection] = []
//                
//                for topic in topics {
//                    switch topic.type {
//                    case .header:
//                        let section = ForumSection(id: topic.id, title: topic.title, typeId: topic.typeId)
//                        sections.append(section)
//                        
//                    case .topic:
//                        let topic = ForumSection(id: topic.id, title: topic.title, typeId: topic.typeId)
//                        
//                        if let lastSection = sections.last {
//                            if let subtopics = lastSection.subtopics {
//                                sections[sections.count - 1].subtopics!.append(topic)
//                            } else {
//                                sections[sections.count - 1].subtopics = []
//                                sections[sections.count - 1].subtopics?.append(topic)
//                            }
//                        }
//                    }
//                }
//
//                state.sections = sections
//                state.topics = topics
//                return .none
//                
//            case let ._forumTopicsResponse(.failure(error)):
//                print(error)
//                return .none
            }
        }
    }
}

public struct ForumSection: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let typeId: Int
    
    public var subtopics: [ForumSection]?
}
