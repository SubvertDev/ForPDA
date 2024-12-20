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
public struct ForumsListFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var forums: [ForumRow] = []
        
        public init(
            forums: [ForumRow] = []
        ) {
            self.forums = forums
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case settingsButtonTapped
        case forumRedirectTapped(URL)
        case forumTapped(id: Int, name: String)
        
        case _forumsListResponse(Result<[ForumInfo], any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                return .run { send in
                    let result = await Result { try await apiClient.getForumsList() }
                    await send(._forumsListResponse(result))
                }
                
            case .forumTapped, .settingsButtonTapped, .forumRedirectTapped:
                return .none
                
            case let ._forumsListResponse(.success(forums)):
                var rows: [ForumRow] = []

                for forum in forums {
                    if forum.isCategory {
                        let category = ForumRow(id: forum.id, title: forum.name, forums: [])
                        rows.append(category)
                    } else {
                        rows[rows.count - 1].forums.append(forum)
                    }
                }
                
                state.forums = rows
                return .none
                
            case let ._forumsListResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}
