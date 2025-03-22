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
import AnalyticsClient

@Reducer
public struct ForumsListFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var forums: [ForumRow]?
        var didLoadOnce = false
        
        public init(
            forums: [ForumRow]? = nil
        ) {
            self.forums = forums
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
        case settingsButtonTapped
        case forumRedirectTapped(URL)
        case forumTapped(id: Int, name: String)
        
        case _forumsListResponse(Result<[ForumInfo], any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                guard state.forums == nil else { return .none }
                return .run { send in
                    for try await forumList in try await apiClient.getForumsList(policy: .cacheOrLoad) {
                        await send(._forumsListResponse(.success(forumList)))
                    }
                } catch: { error, send in
                    await send(._forumsListResponse(.failure(error)))
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
                reportFullyDisplayed(&state)
                return .none
                
            case let ._forumsListResponse(.failure(error)):
                print(error)
                reportFullyDisplayed(&state)
                return .none
            }
        }
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
