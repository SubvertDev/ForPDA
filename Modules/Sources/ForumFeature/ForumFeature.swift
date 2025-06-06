//
//  ForumFeature.swift
//  ForPDA
//
//  Created by Xialtal on 25.10.24.
//

import AnalyticsClient
import APIClient
import ComposableArchitecture
import Foundation
import Models
import PageNavigationFeature
import PasteboardClient
import PersistenceKeys
import TCAExtensions
import ToastClient
import WriteFormFeature

@Reducer
public struct ForumFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        @Presents var writeForm: WriteFormFeature.State?

        public var forumId: Int
        public var forumName: String?
        
        public var forum: Forum?
        public var topics: [TopicInfo] = []
        public var topicsPinned: [TopicInfo] = []
        
        public var isLoadingTopics = false
        public var isRefreshing = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .forum)
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var didLoadOnce = false
        
        public init(
            forumId: Int,
            forumName: String? = nil
        ) {
            self.forumId = forumId
            self.forumName = forumName
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
        case onRefresh
        case topicTapped(TopicInfo, showUnread: Bool)
        case subforumRedirectTapped(URL)
        case subforumTapped(ForumInfo)
        case announcementTapped(id: Int, name: String)
        
        case contextOptionMenu(ForumOptionContextMenuAction)
        case contextTopicMenu(ForumTopicContextMenuAction, TopicInfo)
        case contextCommonMenu(ForumCommonContextMenuAction, Int, Bool)
        
        case writeForm(PresentationAction<WriteFormFeature.Action>)
        
        case pageNavigation(PageNavigationFeature.Action)
        
        case _loadForum(offset: Int)
        case _forumResponse(Result<Forum, any Error>)
        
        case delegate(Delegate)
        public enum Delegate {
            case openTopic(id: Int, name: String, goTo: GoTo)
            case openForum(id: Int, name: String)
            case openAnnouncement(id: Int, name: String)
            case handleRedirect(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.analyticsClient) private var analyticsClient
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
                
            case .writeForm:
                return .none
                
            case let ._loadForum(offset):
                if !state.isRefreshing {
                    state.isLoadingTopics = true
                }
                return .run { [id = state.forumId, perPage = state.appSettings.forumPerPage, isRefreshing = state.isRefreshing] send in
                    let startTime = Date()
                    for try await forum in try await apiClient.getForum(id, offset, perPage, isRefreshing ? .skipCache : .cacheAndLoad) {
                        if isRefreshing { await delayUntilTimePassed(1.0, since: startTime) }
                        await send(._forumResponse(.success(forum)))
                    }
                } catch: { error, send in
                    await send(._forumResponse(.failure(error)))
                }
                
            case .contextOptionMenu(let action):
                switch action {
                case .createTopic:
                    state.writeForm = WriteFormFeature.State(
                        formFor: .topic(
                            forumId: state.forumId,
                            content: ""
                        )
                    )
                    return .none
                    
                    // TODO: sort, to bookmarks
                    // TODO: Add analytics
                default: return .none
                }
                
            case let .contextTopicMenu(action, topic):
                switch action {
                case .open:
                    return .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: .first)))
                    
                case .goToEnd:
                    return .concatenate(
                        .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: .unread))),
                        .send(.onRefresh)
                    )
                }
                
            case .contextCommonMenu(let action, let id, let isForum):
                switch action {
                case .copyLink:
                    let show = isForum ? "showforum" : "showtopic"
                    pasteboardClient.copy("https://4pda.to/forum/index.php?\(show)=\(id)")
                    return .none
                    
                case .openInBrowser:
                    let show = isForum ? "showforum" : "showtopic"
                    let url = URL(string: "https://4pda.to/forum/index.php?\(show)=\(id)")!
                    return .run { _ in await open(url: url) }
                    
                case .markRead:
                    return .run { [id = id, isForum = isForum] send in
                        let response = try await apiClient.markReadForum(id, !isForum)
                        await send(.onRefresh)
                        #warning("add toast")
                    }
                    
                case .setFavorite(let isFavorite):
                    return .run { [id = id, isFavorite = isFavorite, isForum = isForum] send in
                        let request = SetFavoriteRequest(
                            id: id,
                            action: isFavorite ? .delete : .add,
                            type: isForum ? .forum : .topic
                        )
                        let response = try await apiClient.setFavorite(request)
                        await send(.onRefresh)
                        #warning("add toast")
                    } catch: { _, _ in
                        await toastClient.showToast(.whoopsSomethingWentWrong)
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
                reportFullyDisplayed(&state)
                return .none
                
            case let ._forumResponse(.failure(error)):
                reportFullyDisplayed(&state)
                return .run { _ in await toastClient.showToast(.whoopsSomethingWentWrong) }
                
            case let .topicTapped(topic, showUnread):
                return .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: showUnread ? .unread : .first)))
                
            case let .subforumTapped(forum):
                return .send(.delegate(.openForum(id: forum.id, name: forum.name)))
                
            case let .announcementTapped(id: id, name: name):
                return .send(.delegate(.openAnnouncement(id: id, name: name)))
                
            case let .subforumRedirectTapped(url):
                return .send(.delegate(.handleRedirect(url)))
                
            case .delegate:
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
}
