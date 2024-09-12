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
public struct ForumFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var forums: [ForumInfo] = []
        
        public init(
            forums: [ForumInfo] = []
        ) {
            self.forums = forums
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case forumTapped(id: Int)
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
//                    let result = await Result { try await apiClient.getForumsList() }
//                    await send(._forumsListResponse(result))
                }
                
            case .forumTapped(id: _):
                return .run { send in
//                    let result = await Result { try await apiClient.getForumTopic(id: id, page: 0, itemsPerPage: 10) }
                }
                
            case let ._forumsListResponse(.success(forums)):
                state.forums = forums
                return .none
                
            case let ._forumsListResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}
