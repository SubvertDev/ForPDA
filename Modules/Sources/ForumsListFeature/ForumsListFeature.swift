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
        public var forums: [ForumRowInfo]?
        public var isExpanded: [Int: Bool] = [:]
        var didLoadOnce = false
        
        public init(
            forums: [ForumRowInfo]? = nil
        ) {
            self.forums = forums
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case view(View)
        public enum View {
            case onAppear
            case settingsButtonTapped
            case forumRedirectTapped(URL)
            case forumTapped(id: Int, name: String)
            case toggleSection(Int)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case forumsListResponse(Result<[ForumInfo], any Error>)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openSettings
            case openForum(id: Int, name: String)
            case handleForumRedirect(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                guard state.forums == nil else { return .none }
                return .run { send in
                    for try await forumList in try await apiClient.getForumsList(policy: .cacheOrLoad) {
                        await send(.internal(.forumsListResponse(.success(forumList))))
                    }
                } catch: { error, send in
                    await send(.internal(.forumsListResponse(.failure(error))))
                }
                
            case .view(.settingsButtonTapped):
                return .send(.delegate(.openSettings))
                
            case let .view(.forumTapped(id: id, name: name)):
                return .send(.delegate(.openForum(id: id, name: name)))
                
            case let .view(.forumRedirectTapped(url)):
                return .send(.delegate(.handleForumRedirect(url)))
                
            case let .view(.toggleSection(id)):
                state.isExpanded[id]?.toggle()
                return .none
                
            case let .internal(.forumsListResponse(.success(forums))):
                var rows: [ForumRowInfo] = []
                
                for forum in forums {
                    if forum.isCategory {
                        let category = ForumRowInfo(id: forum.id, title: forum.name, forums: [])
                        rows.append(category)
                        state.isExpanded[forum.id] = true
                    } else {
                        rows[rows.count - 1].forums.append(forum)
                    }
                }
                
                state.forums = rows
                reportFullyDisplayed(&state)
                
            case let .internal(.forumsListResponse(.failure(error))):
                #warning("add toast")
                reportFullyDisplayed(&state)
                
            case .delegate:
                break
            }
            
            return .none
        }
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
