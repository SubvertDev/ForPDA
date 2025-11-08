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

@Reducer
public struct ForumFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Enums
    
    public struct SectionExpand: Equatable {
        
        public enum Kind: String, CaseIterable {
            case announcements, subforums, topics, pinnedTopics
        }
        
        private var values: [Kind: Bool] = Dictionary(
            uniqueKeysWithValues: Kind.allCases.map { ($0, true) }
        )
        
        func value(for kind: Kind) -> Bool {
            values[kind, default: true]
        }
        
        mutating func toggle(kind: Kind) {
            values[kind]?.toggle()
        }
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?

        public var forumId: Int
        public var forumName: String?
        public let initialPage: Int?
        
        public var forum: Forum?
        public var topics: [TopicInfo] = []
        public var topicsPinned: [TopicInfo] = []
        public var sectionsExpandState = SectionExpand()
        
        public var isLoadingTopics = false
        public var isRefreshing = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .forum)
        
        public var isUserAuthorized: Bool {
            return userSession != nil
        }
        
        var didLoadOnce = false
        
        public init(
            forumId: Int,
            forumName: String? = nil,
            initialPage: Int? = nil
        ) {
            self.forumId = forumId
            self.forumName = forumName
            self.initialPage = initialPage
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction {
        case pageNavigation(PageNavigationFeature.Action)

        case view(View)
        public enum View {
            case onFirstAppear
            case onNextAppear
            case onRefresh
            case topicTapped(TopicInfo, showUnread: Bool)
            case subforumRedirectTapped(URL)
            case subforumTapped(ForumInfo)
            case announcementTapped(id: Int, name: String)
            case sectionExpandTapped(SectionExpand.Kind)
            
            case contextOptionMenu(ForumOptionContextMenuAction)
            case contextTopicMenu(ForumTopicContextMenuAction, TopicInfo)
            case contextCommonMenu(ForumCommonContextMenuAction, Int, Bool)
        }
                
        case `internal`(Internal)
        public enum Internal {
            case refresh
            case loadForum(offset: Int)
            case forumResponse(Result<Forum, any Error>)
        }
        
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
    @Dependency(\.notificationCenter) private var notificationCenter
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(.internal(.loadForum(offset: newOffset)))
                
            case .pageNavigation:
                return .none
                
            case .view(.onFirstAppear):
                if let page = state.initialPage {
                    return .send(.pageNavigation(.goToPage(newPage: page)))
                } else {
                    return .send(.internal(.loadForum(offset: 0)))
                }
                
            case .view(.onNextAppear):
                return .send(.internal(.refresh))
                
            case .view(.onRefresh):
                return .send(.internal(.refresh))
                
            case let .view(.sectionExpandTapped(kind)):
                state.sectionsExpandState.toggle(kind: kind)
                return .none
                
            case let .view(.topicTapped(topic, showUnread)):
                guard !showUnread else {
                    return .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: .unread)))
                }
                let goTo = state.appSettings.topicOpeningStrategy.asGoTo
                return .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: goTo)))
                
            case let .view(.subforumTapped(forum)):
                return .send(.delegate(.openForum(id: forum.id, name: forum.name)))
                
            case let .view(.announcementTapped(id: id, name: name)):
                return .send(.delegate(.openAnnouncement(id: id, name: name)))
                
            case let .view(.subforumRedirectTapped(url)):
                return .send(.delegate(.handleRedirect(url)))
                
            case .view(.contextOptionMenu(let action)):
                switch action {
                    // TODO: sort, to bookmarks
                    // TODO: Add analytics
                default: return .none
                }
                
            case let .view(.contextTopicMenu(action, topic)):
                switch action {
                case .open:
                    return .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: .first)))
                    
                case .goToEnd:
                    return .concatenate(
                        .send(.delegate(.openTopic(id: topic.id, name: topic.name, goTo: .unread))),
                        .send(.internal(.refresh))
                    )
                }
                
            case .view(.contextCommonMenu(let action, let id, let isForum)):
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
                    return .run { [id, isForum] send in
                        let _ = try await apiClient.markRead(id: id, isTopic: !isForum)
                        await send(.internal(.refresh))
                    }
                    
                case .setFavorite(let isFavorite):
                    return .run { [id = id, isFavorite = isFavorite, isForum = isForum] send in
                        let request = SetFavoriteRequest(
                            id: id,
                            action: isFavorite ? .delete : .add,
                            type: isForum ? .forum : .topic
                        )
                        let _ = try await apiClient.setFavorite(request)
                        notificationCenter.post(name: .favoritesUpdated, object: nil)
                        await send(.internal(.refresh))
                        // TODO: We don't know if it's added or removed from api
                        // let text: LocalizedStringResource
                        // if isAdded {
                        //     text = LocalizedStringResource("Added to favorites", bundle: .module)
                        // } else {
                        //     text = LocalizedStringResource("Removed from favorites", bundle: .module)
                        // }
                        // let toast = ToastMessage(text: text, haptic: .success)
                        // await toastClient.showToast(toast)
                    } catch: { _, _ in
                        await toastClient.showToast(.whoopsSomethingWentWrong)
                    }
                }
                
            case .internal(.refresh):
                state.isRefreshing = true
                return .run { [offset = state.pageNavigation.offset] send in
                    await send(.internal(.loadForum(offset: offset)))
                }
                
            case let .internal(.loadForum(offset)):
                if !state.isRefreshing {
                    state.isLoadingTopics = true
                }
                return .run { [id = state.forumId, perPage = state.appSettings.forumPerPage, isRefreshing = state.isRefreshing] send in
                    let startTime = Date()
                    for try await forum in try await apiClient.getForum(id, offset, perPage, isRefreshing ? .skipCache : .cacheAndLoad) {
                        if isRefreshing { await delayUntilTimePassed(1.0, since: startTime) }
                        await send(.internal(.forumResponse(.success(forum))))
                    }
                } catch: { error, send in
                    await send(.internal(.forumResponse(.failure(error))))
                }
                
            case let .internal(.forumResponse(.success(forum))):
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
                
            case .internal(.forumResponse(.failure)):
                reportFullyDisplayed(&state)
                return .run { _ in await toastClient.showToast(.whoopsSomethingWentWrong) }
                
            case .delegate:
                return .none
            }
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
