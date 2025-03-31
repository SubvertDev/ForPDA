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
import WriteFormFeature
import TCAExtensions
import AnalyticsClient
import TopicBuilder

@Reducer
public struct TopicFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        @Presents var writeForm: WriteFormFeature.State?

        public let topicId: Int
        public let initialOffset: Int
        public var postId: Int?
        var topic: Topic?
        
        var types: [[TopicTypeUI]] = []
        
        var isFirstPage = true
        var isLoadingTopic = true
        var isRefreshing = false
        
        var pageNavigation = PageNavigationFeature.State(type: .topic)
        
        var didLoadOnce = false
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        public init(
            topicId: Int,
            initialOffset: Int = 0,
            postId: Int? = nil,
            topic: Topic? = nil
        ) {
            self.topicId = topicId
            self.postId = postId
            self.topic = topic
            
            // If we open this screen with Go To End usage then we can get offset like 99
            // which means that we need to lower it to 80 (if topicPerPage is 20) with remainder
            // so we can get full page of posts instead only last one post
            self.initialOffset = initialOffset - (initialOffset % _appSettings.topicPerPage.wrappedValue)
//            self.initialOffset = _appSettings.topicPerPage.wrappedValue * (targetPage - 1)
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case onRefresh
        case onSceneBecomeActive
        case userAvatarTapped(userId: Int)
        case urlTapped(URL)
        case pageNavigation(PageNavigationFeature.Action)
        
        case contextMenu(TopicContextMenuAction)
        case contextPostMenu(TopicPostContextMenuAction)
        
        case writeForm(PresentationAction<WriteFormFeature.Action>)
        
        case _loadTopic(offset: Int)
        case _loadTypes([[TopicTypeUI]])
        case _topicResponse(Result<Topic, any Error>)
        case _setFavoriteResponse(Bool)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.analyticsClient) private var analyticsClient
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
                return .concatenate(
                    updatePageNavigation(&state, offset: state.initialOffset),
                    .cancel(id: CancelID.loading),
                    .send(._loadTopic(offset: state.initialOffset))
                )
                
            case .onRefresh:
                state.isRefreshing = true
                return .run { [offset = state.pageNavigation.offset] send in
                    await send(._loadTopic(offset: offset))
                }
                
            case .onSceneBecomeActive:
                if state.isLoadingTopic || state.isRefreshing {
                    return .none
                } else {
                    return .send(.onRefresh)
                }
                
            case .userAvatarTapped:
                // TODO: Wrap into Delegate action?
                return .none
                
            case .urlTapped:
                // TODO: Wrap into Delegate action?
                return .none
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                state.isRefreshing = false
                return .concatenate([
                    .run { [isLastPage = state.pageNavigation.isLastPage, topicId = state.topicId] _ in
                        if isLastPage {
                            await cacheClient.deleteTopicIdOfUnreadItem(topicId)
                        }
                    },
                    .cancel(id: CancelID.loading),
                    .send(._loadTopic(offset: newOffset))
                ])
                
            case .writeForm(.presented(.writeFormSent(let response))):
                if case let .post(data) = response {
                    state.postId = data.id
                    return .send(.pageNavigation(.lastPageTapped))
                }
                return .none
                
            case .writeForm:
                return .none
                
            case .pageNavigation:
                return .none
                
            case .contextMenu(let action):
                guard let topic = state.topic else { return .none }
                switch action {
                case .writePost:
                    state.writeForm = WriteFormFeature.State(
                        formFor: .post(topicId: topic.id, content: .simple("", []))
                    )
                    return .none
                    
                case .openInBrowser:
                    let url = URL(string: "https://4pda.to/forum/index.php?showtopic=\(topic.id)")!
                    return .run { _ in await open(url: url) }
                    
                case .copyLink:
                    pasteboardClient.copy("https://4pda.to/forum/index.php?showtopic=\(topic.id)")
                    return .none
                    
                case .setFavorite:
                    return .run { [id = state.topicId] send in
                        let request = SetFavoriteRequest(id: id, action: topic.isFavorite ? .delete : .add, type: .topic)
                        _ = try await apiClient.setFavorite(request)
                        await send(._setFavoriteResponse(!topic.isFavorite))
                        
                        // TODO: Display toast on success/error.
                    } catch: { error, send in
                        logger.error("Failed to set favorite: \(error)")
                    }
                    
                case .goToEnd:
                    return .send(.pageNavigation(.lastPageTapped))
                }
                
            case .contextPostMenu(let action):
                switch action {
                case .reply(let authorId, let authorName):
                    state.writeForm = WriteFormFeature.State(formFor: .post(
                        topicId: state.topicId,
                        content: .simple("[SNAPBACK]\(authorId)[/SNAPBACK] [B]\(authorName)[/B], ", [])
                    ))
                    return .none
                }
                
            case let ._loadTopic(offset):
                state.isFirstPage = offset == 0
                if !state.isRefreshing {
                    state.isLoadingTopic = true
                }
                return .run { [id = state.topicId, perPage = state.appSettings.topicPerPage, isRefreshing = state.isRefreshing] send in
                    let startTime = Date()
                    let topic = try await apiClient.getTopic(id, offset, perPage)
                    if isRefreshing { await delayUntilTimePassed(1.0, since: startTime) }
                    await send(._topicResponse(.success(topic)))
                } catch: { error, send in
                    await send(._topicResponse(.failure(error)))
                }
                .cancellable(id: CancelID.loading)
                
            case let ._topicResponse(.success(topic)):
                //customDump(topic)
                state.topic = topic

                return .concatenate(
                    updatePageNavigation(&state),
                    .run { [isFirstPage = state.isFirstPage, topicPerPage = state.appSettings.topicPerPage] send in
                        var topicTypes: [[TopicTypeUI]] = []
                        
                        topicTypes = await withTaskGroup(of: (Int, [TopicTypeUI]).self, returning: [[TopicTypeUI]].self) { taskGroup in
                            for (index, post) in topic.posts.enumerated() {
                                // guard index == 0 else { continue } // For test purposes
                                var text = post.content
                                // print(post)
                                if index == 0 && !isFirstPage {
                                    text = "" // Not loading hat post for non-first page
                                }
                                taskGroup.addTask {
                                    return (index, TopicNodeBuilder(text: text, attachments: post.attachments).build())
                                }
                            }
                            
                            var types = Array<[TopicTypeUI]?>(repeating: nil, count: topicPerPage + 1)
                            for await (index, result) in taskGroup {
                                types[index] = result
                            }
                            return types.map { $0 ?? [] }
                        }
                        await send(._loadTypes(topicTypes))
                    }.cancellable(id: CancelID.loading)
                )
                
            case let ._loadTypes(types):
                state.types = types
                state.isLoadingTopic = false
                state.isRefreshing = false
                reportFullyDisplayed(&state)
                return .none
//                return PageNavigationFeature()
//                    .reduce(into: &state.pageNavigation, action: .nextPageTapped)
//                    .map(Action.pageNavigation)
                
            case let ._topicResponse(.failure(error)):
                print("TOPIC RESPONSE FAILURE: \(error)")
                state.isRefreshing = false
                reportFullyDisplayed(&state)
                return .none
                
            case let ._setFavoriteResponse(isFavorite):
                state.topic?.isFavorite = isFavorite
                notificationCenter.send(.favoritesUpdated)
                return .none
            }
        }
        .ifLet(\.$writeForm, action: \.writeForm) {
            WriteFormFeature()
        }
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
    
    private func updatePageNavigation(_ state: inout TopicFeature.State, offset: Int? = nil) -> Effect<Action> {
        return PageNavigationFeature()
            .reduce(
                into: &state.pageNavigation,
                action: .update(
                    count: state.topic?.postsCount ?? 0,
                    offset: offset
                )
            )
            .map(Action.pageNavigation)
    }
}

func measureElapsedTime(_ operation: () throws -> Void) throws -> UInt64 {
    let startTime = DispatchTime.now()
    try operation()
    let endTime = DispatchTime.now()

    let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
    let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0

    return UInt64(elapsedTimeInMilliSeconds)
}

func measureAverageTime(timesToRun: Int, _ operation: () throws -> Void) throws {
    var times = [UInt64]()
    for _ in 0..<timesToRun {
        let time = try measureElapsedTime(operation)
        times.append(time)
    }
    let time = times.reduce(0, +) / UInt64(times.count)
    print("Average time after \(timesToRun) runs: \(time) ms")
}
