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
import FormFeature
import ForumStatFeature
import ForumMoveFeature
import TopicEditFeature

@Reducer
public struct ForumFeature: Reducer, Sendable {
    
    public init() {}
    
	// MARK: - Localizations
    
    public enum Localization {
        static let linkCopied = LocalizedStringResource("Link copied", bundle: .module)
        static let topicEdited = LocalizedStringResource("The topic has been edited", bundle: .module)
        static let markAsReadSuccess = LocalizedStringResource("Marked as read", bundle: .module)
    }

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
    
    // MARK: - Destinations
    
    @Reducer
    public enum Destination {
        case form(FormFeature)
        case move(ForumMoveFeature)
		case stat(ForumStatFeature)
        case edit(TopicEditFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        @Shared(.userSession) var userSession: UserSession?
        
        @Presents public var destination: Destination.State?

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
        case destination(PresentationAction<Destination.Action>)
        case pageNavigation(PageNavigationFeature.Action)

        case view(View)
        public enum View {
            case onFirstAppear
            case onNextAppear
            case onRefresh
            case searchButtonTapped
            case topicTapped(TopicInfo, showUnread: Bool)
            case subforumRedirectTapped(URL)
            case subforumTapped(ForumInfo)
            case announcementTapped(id: Int, name: String)
            case globalAnnouncementUrlTapped(URL)
            case sectionExpandTapped(SectionExpand.Kind)
            
            case contextOptionMenu(ForumOptionContextMenuAction)
            case contextTopicMenu(ForumTopicContextMenuAction, TopicInfo)
            case contextTopicToolsMenu(ForumTopicToolsContextMenuAction)
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
            case openUser(id: Int)
            case openTopic(id: Int, name: String, goTo: GoTo)
            case openForum(id: Int, name: String)
            case openAnnouncement(id: Int, name: String)
            case openSearch(on: SearchOn, navigation: ForumInfo?)
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
                
            case let .destination(.presented(.form(.delegate(.formSent(.topic(id)))))):
                return .send(.delegate(.openTopic(id: id, name: "", goTo: .first)))
                
            case let .destination(.presented(.stat(.delegate(.userTapped(id))))):
                return .send(.delegate(.openUser(id: id)))
                
            case .destination(.presented(.edit(.delegate(.topicEdited)))):
                return .run { _ in
                    await toastClient.showToast(ToastMessage(text: Localization.topicEdited, haptic: .success))
                }
                
            case .destination, .pageNavigation:
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
                
            case .view(.searchButtonTapped):
                let navigation: ForumInfo? = if let forum = state.forum {
                    ForumInfo(id: forum.id, name: forum.name, flag: forum.flag)
                } else { nil }
                return .send(.delegate(.openSearch(
                    on: .forum(ids: [state.forumId], sIn: .all, asTopics: false),
                    navigation: navigation
                )))
                
            case let .view(.globalAnnouncementUrlTapped(url)):
                return .send(.delegate(.handleRedirect(url)))
                
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
                case .createTopic:
                    let formState = FormFeature.State(
                        type: .topic(
                            forumId: state.forumId,
                            content: []
                        )
                    )
                    state.destination = .form(formState)
                    return .none
                    
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
                    
                case .edit:
                    state.destination = .edit(TopicEditFeature.State(
                        id: topic.id,
                        flag: topic.flag,
                        title: topic.name,
                        description: topic.description,
                        supportsPoll: false
                    ))
                    return .none
                }
                
            case let .view(.contextTopicToolsMenu(action)):
                switch action {
                case .move(let topicId):
                    state.destination = .move(ForumMoveFeature.State(type: .topic(topicId)))
                    return .none
                    
                case .modify(let action, let topicId, let isUndo):
                    return .run { send in
                        let status = try await apiClient.modifyForum(
                            ids: [topicId],
                            type: .topic(action),
                            isUndo: isUndo
                        )
                        await send(.internal(.refresh))
                        await toastClient.showToast(status ? .actionCompleted : .whoopsSomethingWentWrong)
                    } catch: { error, send in
                        analyticsClient.capture(error)
                        await toastClient.showToast(.whoopsSomethingWentWrong)
                    }
                }
                
            case .view(.contextCommonMenu(let action, let id, let isForum)):
                switch action {
                case .copyLink:
                    let show = isForum ? "showforum" : "showtopic"
                    pasteboardClient.copy("https://4pda.to/forum/index.php?\(show)=\(id)")
                    return .run { _ in
                        await toastClient.showToast(ToastMessage(text: Localization.linkCopied, haptic: .success))
                    }
                    
                case .openInBrowser:
                    let show = isForum ? "showforum" : "showtopic"
                    let url = URL(string: "https://4pda.to/forum/index.php?\(show)=\(id)")!
                    return .run { _ in await open(url: url) }
                    
                case .markRead:
                    return .run { [id, isForum] send in
                        let status = try await apiClient.markRead(id: id, isTopic: !isForum)
                        let markedAsRead = ToastMessage(text: Localization.markAsReadSuccess, haptic: .success)
                        await toastClient.showToast(status ? markedAsRead : .whoopsSomethingWentWrong)
                        await send(.internal(.refresh))
                    }
                    
                case .stat:
                    state.destination = .stat(ForumStatFeature.State(type: .forum(id: state.forumId)))
                    return .none
                    
                case .setFavorite(let isFavorite):
                    return .run { [id = id, isFavorite = isFavorite, isForum = isForum] send in
                        let request = SetFavoriteRequest(
                            id: id,
                            action: isFavorite ? .delete : .add,
                            type: isForum ? .forum : .topic
                        )
                        let status = try await apiClient.setFavorite(request)
                        notificationCenter.post(name: .favoritesUpdated, object: nil)
                        await send(.internal(.refresh))
                        await toastClient.showToast(status ? .actionCompleted : .whoopsSomethingWentWrong)
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
        .ifLet(\.$destination, action: \.destination)
        
        Analytics()
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}

extension ForumFeature.Destination.State: Equatable {}
