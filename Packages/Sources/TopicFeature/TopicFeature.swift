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
import PasteboardClient
import NotificationCenterClient
import TCAExtensions

@Reducer
public struct TopicFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings

        public let topicId: Int
        public var offset: Int
        var topic: Topic?
        
        var types: [[TopicTypeUI]] = []
        
        var isFirstPage = true
        var isLoadingTopic = true
        
        var pageNavigation = PageNavigationFeature.State(type: .topic)
        
        public init(
            topicId: Int,
            offset: Int = 0,
            topic: Topic? = nil
        ) {
            self.topicId = topicId
            self.offset = offset
            self.topic = topic
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case userAvatarTapped(userId: Int)
        case urlTapped(URL)
        case pageNavigation(PageNavigationFeature.Action)
        
        case contextMenu(TopicContextMenuAction)
        
        case _loadTopic(offset: Int)
        case _loadTypes([[TopicTypeUI]])
        case _topicResponse(Result<Topic, any Error>)
        case _setFavoriteResponse(Bool)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.pasteboardClient) private var pasteboardClient
    @Dependency(\.notificationCenter) private var notificationCenter
    @Dependency(\.logger) var logger
    
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
                guard state.topic == nil else { return .none }
                return .send(.pageNavigation(.offsetChanged(to: state.offset)))
                
            case .userAvatarTapped:
                // TODO: Wrap into Delegate action?
                return .none
                
            case .urlTapped:
                // TODO: Wrap into Delegate action?
                return .none

            case let .pageNavigation(.offsetChanged(to: newOffset)):
                state.offset = if newOffset == 0 { newOffset } else {
                    (newOffset + 1) - state.appSettings.topicPerPage
                }
                state.isFirstPage = newOffset == 0
                return .concatenate([
                    .cancel(id: CancelID.loading),
                    .send(._loadTopic(offset: state.offset))
                ])
                
            case .pageNavigation:
                return .none
                
            case .contextMenu(let action):
                switch action {
                case .openInBrowser:
                    guard let topic = state.topic else { return .none }
                    let url = URL(string: "https://4pda.to/forum/index.php?showtopic=\(topic.id)")!
                    return .run { _ in await open(url: url) }
                    
                case .copyLink:
                    guard let topic = state.topic else { return .none }
                    pasteboardClient.copy(string: "https://4pda.to/forum/index.php?showtopic=\(topic.id)")
                    return .none
                    
                case .setFavorite:
                    guard let topic = state.topic else { return .none }
                    return .run { [id = state.topicId] send in
                        let request = SetFavoriteRequest(id: id, action: topic.isFavorite ? .delete : .add, type: .topic)
                        try await apiClient.setFavorite(request)
                        await send(._setFavoriteResponse(!topic.isFavorite))
                        
                        // TODO: Display toast on success/error.
                    } catch: { error, send in
                        logger.error("Failed to set favorite: \(error)")
                    }
                    
                case .goToEnd:
                    // TODO: Implement.
                    return .none
                }
                
            case let ._loadTopic(offset):
                state.isLoadingTopic = true
                return .run { [id = state.topicId, perPage = state.appSettings.topicPerPage] send in
                    let result = await Result { try await apiClient.getTopic(id, offset, perPage) }
                    await send(._topicResponse(result))
                }
                .cancellable(id: CancelID.loading)
                
            case let ._topicResponse(.success(topic)):
                //customDump(topic)
                state.topic = topic
                
                // FIXME: Quickfix for good pagination.
                state.pageNavigation.count = topic.postsCount
                state.pageNavigation.offset = if state.offset == 0 { 0 } else {
                    (state.offset - 1) + state.appSettings.topicPerPage
                }
                
                return .run { send in
                    var topicTypes: [[TopicTypeUI]] = []
                    let builder = TopicBuilder()
                    logger.error("[LOG] Start processing topic: \(Date.now)")
                    for post in topic.posts {
                        logger.error("[LOG] Start parsing \(post.id): \(Date.now)")
                        if let types = await cacheClient.getParsedPostContent(post.id) {
                            topicTypes.append(types)
                        } else {
                            logger.error("[LOG] Start parsing \(post.id): \(Date.now)")
                            let parsedContent = BBCodeParser.parse(post.content)!
                            logger.error("[LOG] Start building \(post.id): \(Date.now)")
                            let types = try! builder.build(from: parsedContent)
                            logger.error("[LOG] Start caching \(post.id): \(Date.now)")
                            await cacheClient.cacheParsedPostContent(post.id, types)
                            topicTypes.append(types)
                        }
                        logger.error("[LOG] Stop processing \(post.id): \(Date.now)")
                    }
                    logger.error("[LOG] Finish processing topic: \(Date.now)")
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
                
            case let ._setFavoriteResponse(isFavorite):
                state.topic?.isFavorite = isFavorite
                notificationCenter.send(.favoritesUpdated)
                return .none
            }
        }
    }
}
