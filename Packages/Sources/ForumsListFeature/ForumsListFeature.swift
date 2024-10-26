//
//  ForumFeature.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct ForumsListFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var forums: [ForumStructure] = []
        
        public init(
            forums: [ForumStructure] = []
        ) {
            self.forums = forums
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case settingsButtonTapped
        case forumTapped(id: Int, name: String)
        case _forumsListResponse(Result<[ForumInfo], any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { send in
                    let result = await Result { try await apiClient.getForumsList() }
                    await send(._forumsListResponse(result))
                }
                
            case .forumTapped, .settingsButtonTapped:
                return .none
                
            case let ._forumsListResponse(.success(forums)):
                var structures: [ForumStructure] = []

                for forum in forums {
                    if forum.isCategory {
                        let category = ForumStructure(id: forum.id, title: forum.name, forums: [])
                        structures.append(category)
                    } else {
                        structures[structures.count - 1].forums.append(forum)
                    }
                }
                
                state.forums = structures
                return .none
                
            case let ._forumsListResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}

public struct ForumStructure: Equatable, Identifiable {
    public let id: Int
    public let title: String
    public var forums: [ForumInfo]
    
    public init(id: Int, title: String, forums: [ForumInfo]) {
        self.id = id
        self.title = title
        self.forums = forums
    }
}
