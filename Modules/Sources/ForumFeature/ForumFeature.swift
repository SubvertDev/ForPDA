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
        case topicTapped(id: Int, offset: Int)
        case subforumRedirectTapped(URL)
        case subforumTapped(id: Int, name: String)
        case announcementTapped(id: Int, name: String)
        
        case contextOptionMenu(ForumOptionContextMenuAction)
        case contextTopicMenu(ForumTopicContextMenuAction, Int)
        case contextCommonMenu(ForumCommonContextMenuAction, Int, Bool)
        
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
                return .run { [offset = state.pageNavigation.offset] send in
                    await send(._loadForum(offset: offset))
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
                
            case .contextOptionMenu(let action):
                switch action {
                // TODO: sort, to bookmarks
                default: return .none
                }
                
            case .contextTopicMenu(let action, let id):
                switch action {
                case .open:
                    return .send(.topicTapped(id: id, offset: 0))
                
                case .goToEnd:
                    return .run { [id = id] send in
                        let request = JumpForumRequest(postId: 0, topicId: id, allPosts: true, type: .last)
                        let response = try await apiClient.jumpForum(request: request)
                        
                        await send(.onRefresh)
                        await send(.topicTapped(id: id, offset: response.offset))
                    }
                }
            
            case .contextCommonMenu(let action, let id, let isForum):
                switch action {
                case .copyLink:
                    let show = isForum ? "showforum" : "showtopic"
                    pasteboardClient.copy(string: "https://4pda.to/forum/index.php?\(show)=\(id)")
                    return .none
                    
                case .openInBrowser:
                    let show = isForum ? "showforum" : "showtopic"
                    let url = URL(string: "https://4pda.to/forum/index.php?\(show)=\(id)")!
                    return .run { _ in await open(url: url) }
                    
                case .markRead:
                    return .run { [id = id, isForum = isForum] send in
                        _ = try await apiClient.markReadForum(id: id, isTopic: !isForum)
                        // TODO: Display toast on success/error.
                    }
                    
                case .setFavorite(let isFavorite):
                    return .run { [id = id, isFavorite = isFavorite, isForum = isForum] send in
                        let request = SetFavoriteRequest(
                            id: id,
                            action: isFavorite ? .delete : .add,
                            type: isForum ? .forum : .topic
                        )
                        _ = try await apiClient.setFavorite(request)
                        // TODO: Display toast on success/error.
                    }
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
