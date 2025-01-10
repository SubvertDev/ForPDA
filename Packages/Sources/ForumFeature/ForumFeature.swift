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
import PasteboardClient
import PersistenceKeys
import TCAExtensions

@Reducer
public struct ForumFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings

        public var forumId: Int
        public var forumName: String?
        
        public var forum: Forum?
        public var topics: [TopicInfo] = []
        public var topicsPinned: [TopicInfo] = []
        
        public var isLoadingTopics = false
        public var isRefreshing = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .forum)
        
        public init(
            forumId: Int,
            forumName: String?
        ) {
            self.forumId = forumId
            self.forumName = forumName
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
        case onRefresh
        case settingsButtonTapped
        case topicTapped(id: Int)
        case subforumRedirectTapped(URL)
        case subforumTapped(id: Int, name: String)
        case announcementTapped(id: Int, name: String)
        
        case contextMenu(ForumContextMenuAction)
        
        case pageNavigation(PageNavigationFeature.Action)
        
        case _loadForum(offset: Int)
        case _forumResponse(Result<Forum, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                guard state.forum == nil else { return .none }
                return .send(._loadForum(offset: 0))
                
            case .onRefresh:
                state.isRefreshing = true
                return .run { send in
                    await send(._loadForum(offset: 0))
                }
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(._loadForum(offset: newOffset))
                
            case .pageNavigation:
                return .none
                
            case let ._loadForum(offset):
                if !state.isRefreshing {
                    state.isLoadingTopics = true
                }
                return .run { [id = state.forumId, perPage = state.appSettings.forumPerPage, isRefreshing = state.isRefreshing] send in
                    let startTime = Date()
                    for try await forum in try await apiClient.getForum(id: id, page: offset, perPage: perPage, policy: isRefreshing ? .skipCache : .cacheAndLoad) {
                        if isRefreshing { await delayUntilTimePassed(1.0, since: startTime) }
                        await send(._forumResponse(.success(forum)))
                    }
                } catch: { error, send in
                    await send(._forumResponse(.failure(error)))
                }
                
            case .settingsButtonTapped:
                return .none
                
            case .topicTapped:
                return .none
            
            case .subforumTapped:
                return .none
                
            case .announcementTapped:
                return .none
                
            case .subforumRedirectTapped:
                return .none
                
            case .contextMenu(let action):
                switch action {
                case .openInBrowser:
                    guard let forum = state.forum else { return .none }
                    let url = URL(string: "https://4pda.to/forum/index.php?showforum=\(forum.id)")!
                    return .run { _ in await open(url: url) }
                    
                case .copyLink:
                    guard let forum = state.forum else { return .none }
                    pasteboardClient.copy(string: "https://4pda.to/forum/index.php?showforum=\(forum.id)")
                    return .none
                
                case .setFavorite:
                    guard let forum = state.forum else { return .none }
                    return .run { [id = state.forumId] send in
                        let request = SetFavoriteRequest(id: id, action: forum.isFavorite ? .delete : .add, type: .forum)
                        _ = try await apiClient.setFavorite(request)
                        // TODO: Display toast on success/error.
                    }
                
                // TODO: sort, to bookmarks
                default: return .none
                }
                
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
                state.forumName = state.forumName ?? forum.name
                
                if !pinnedTopics.isEmpty {
                    state.topicsPinned = pinnedTopics
                }
                
                // TODO: Is it ok?
                state.pageNavigation.count = forum.topicsCount
                
                state.isLoadingTopics = false
                state.isRefreshing = false
                
                return .none
                
            case let ._forumResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}
