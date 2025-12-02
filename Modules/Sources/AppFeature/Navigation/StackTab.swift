//
//  StackTab.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 30.03.2025.
//

import Foundation

import AnalyticsClient
import DeeplinkHandler
import Models
import TCAExtensions

import ComposableArchitecture
import ArticleFeature
import SettingsFeature
import NotificationsFeature
import DeveloperFeature
import ForumFeature
import TopicFeature
import FavoritesRootFeature
import FavoritesFeature
import ProfileFeature
import AnnouncementFeature
import HistoryFeature
import QMSListFeature
import QMSFeature
import ReputationFeature
import AuthFeature
import SearchResultFeature

@Reducer
public struct StackTab: Reducer, Sendable {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var root: Path.State
        public var path: StackState<Path.State>
        public var showTabBar: Bool
        
        public init(
            root: Path.State,
            path: StackState<Path.State> = .init(),
            showTabBar: Bool = true
        ) {
            self.root = root
            self.path = path
            self.showTabBar = showTabBar
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case root(Path.Action)
        case path(StackActionOf<Path>)
        
        case delegate(Delegate)
        public enum Delegate {
            case showTabBar(Bool)
            case switchTab(to: AppTab)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.analyticsClient) private var analytics
    @Dependency(\.notificationCenter) private var notificationCenter
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.root, action: \.root) {
            Path.body
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .root(pathAction), let .path(.element(id: _, action: pathAction)):
                return handleNavigation(action: pathAction, state: &state)
                
            case .path, .delegate:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .onChange(of: \.path) { _, path in
            Reduce<State, Action> { state, action in
                let hasArticle = path.contains(where: { $0.is(\.articles.article) })
                let hasSettings = path.contains(where: { $0.is(\.settings) })
                let hasQms = path.contains(where: { $0.is(\.qms) })
                let showTabBar = !hasArticle && !hasSettings && !hasQms
                if state.showTabBar != showTabBar {
                    state.showTabBar = showTabBar
                    return .send(.delegate(.showTabBar(state.showTabBar)))
                }
                return .none
            }
        }
    }
    
    // MARK: - Navigation
    
    private func handleNavigation(action: Path.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .articles(action):
            return handleArticlesPathNavigation(action: action, state: &state)
            
        case let .favorites(action):
            return handleFavoritesPathNavigation(action: action, state: &state)
            
        case let .forum(action):
            return handleForumPathNavigation(action: action, state: &state)
            
        case let .profile(action):
            return handleProfilePathNavigation(action: action, state: &state)
            
        case let .settings(action):
            return handleSettingsPathNavigation(action: action, state: &state)
            
        case let .qms(action):
            return handleQMSPathNavigation(action: action, state: &state)
            
        case let .auth(action):
            return handleAuthNavigation(action: action, state: &state)
        }
    }
    
    // MARK: - Articles
    
    private func handleArticlesPathNavigation(action: Path.Articles.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .articlesList(.delegate(.openArticle(preview))):
            state.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
            
        case let .articlesList(.delegate(.openSearch(options))):
            state.path.append(.articles(.search(SearchResultFeature.State(search: options))))
            
        case let .article(.delegate(.handleDeeplink(id))):
            let preview = ArticlePreview.innerDeeplink(id: id)
            state.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
            
        case .articlesList(.delegate(.openUserProfile(let id))),
             .article(.comments(.element(id: _, action: .profileTapped(let id)))):
            state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
            
            // Search
            
        case let .search(.delegate(.openArticle(preview))):
            state.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Favorites
    
    private func handleFavoritesPathNavigation(action: FavoritesFeature.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .delegate(.openForum(id: id, name: name)):
            state.path.append(.forum(.forum(ForumFeature.State(forumId: id, forumName: name))))
            
        case let .delegate(.openTopic(id: id, name: name, goTo: goTo)):
            state.path.append(.forum(.topic(TopicFeature.State(topicId: id, topicName: name, goTo: goTo))))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Forum
    
    private func handleForumPathNavigation(action: Path.Forum.Action, state: inout State) -> Effect<Action> {
        switch action {
            
            // Forum List
            
        case let .forumList(.delegate(.openForum(id: id, name: name))):
            state.path.append(.forum(.forum(ForumFeature.State(forumId: id, forumName: name))))
            
        case let .forumList(.delegate(.handleForumRedirect(url))):
            return handleDeeplink(url: url, state: &state)
            
            // Forum
            
        case let .forum(.delegate(.openAnnouncement(id: id, name: name))):
            state.path.append(.forum(.announcement(AnnouncementFeature.State(id: id, name: name))))
            
        case let .forum(.delegate(.openForum(id: id, name: name))):
            state.path.append(.forum(.forum(ForumFeature.State(forumId: id, forumName: name))))
            
        case let .forum(.delegate(.openTopic(id: id, name: name, goTo: goTo))):
            state.path.append(.forum(.topic(TopicFeature.State(topicId: id, topicName: name, goTo: goTo))))
            
        case let .forum(.delegate(.openUserProfile(id))):
            state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
            
        case let .forum(.delegate(.openSearch(options))):
            state.path.append(.forum(.search(SearchResultFeature.State(search: options))))
            
        case let .forum(.delegate(.handleRedirect(url))):
            return handleDeeplink(url: url, state: &state)
                        
            // Topic
            
        case let .topic(.delegate(.handleUrl(url))):
            return handleDeeplink(url: url, state: &state)
            
        case let .topic(.delegate(.openUser(id: id))):
            state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
            
        case let .topic(.delegate(.openSearch(options))):
            state.path.append(.forum(.search(SearchResultFeature.State(search: options))))
            
        case .topic(.delegate(.openedLastPage)):
            for (id, element) in zip(state.path.ids, state.path).reversed() where element.is(\.forum.forum) {
                return reduce(into: &state, action: .path(.element(id: id, action: .forum(.forum(.internal(.refresh))))))
            }
            
            // Announcement
            
        case let .announcement(.delegate(.handleUrl(url))):
            return handleDeeplink(url: url, state: &state)
            
            // Search
            
        case let .search(.delegate(.openTopic(id, goTo))):
            state.path.append(.forum(.topic(TopicFeature.State(topicId: id, goTo: goTo))))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Profile
    
    private func handleProfilePathNavigation(action: Path.Profile.Action, state: inout State) -> Effect<Action> {
        switch action {
        case .profile(.delegate(.openHistory)):
            state.path.append(.profile(.history(HistoryFeature.State())))
            
        case let .profile(.delegate(.openReputation(id))):
            state.path.append(.profile(.reputation(ReputationFeature.State(userId: id))))
            
        case .profile(.delegate(.openQms)):
            state.path.append(.qms(.qmsList(QMSListFeature.State())))
            
        case .profile(.delegate(.openSettings)):
            state.path.append(.settings(.settings(SettingsFeature.State())))
            
        case let .profile(.delegate(.handleUrl(url))):
            return handleDeeplink(url: url, state: &state)
            
        case let .history(.delegate(.openTopic(id: id, name: name, goTo: goTo))):
            state.path.append(.forum(.topic(TopicFeature.State(topicId: id, topicName: name, goTo: goTo))))
            
        case let .reputation(.delegate(.openProfile(id))):
            state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
            
        case let .reputation(.delegate(.openTopic(topicId: topicId, name: name, goTo: goTo))):
            state.path.append(.forum(.topic(TopicFeature.State(topicId: topicId, topicName: name, goTo: goTo))))
            
        case let .reputation(.delegate(.openArticle(articleId: articleId))):
            let preview = ArticlePreview.innerDeeplink(id: articleId)
            state.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Settings
    
    private func handleSettingsPathNavigation(action: Path.Settings.Action, state: inout State) -> Effect<Action> {
        switch action {
        case .settings(.delegate(.openNavigationSettings)):
            state.path.append(.settings(.navigation(NavigationSettingsFeature.State())))
            
        case .settings(.delegate(.openNotificationsSettings)):
            state.path.append(.settings(.notifications(NotificationsFeature.State())))
            
        case .settings(.delegate(.openDeveloperMenu)):
            state.path.append(.settings(.developer(DeveloperFeature.State())))
            
        case let .settings(.delegate(.openDeeplink(url))):
            return handleDeeplink(url: url, state: &state)
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - QMS
    
    private func handleQMSPathNavigation(action: Path.QMS.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .qmsList(.delegate(.openQMSChat(id))):
            state.path.append(.qms(.qms(QMSFeature.State(chatId: id))))
            
        case let .qms(.delegate(.handleUrl(url))):
            return handleDeeplink(url: url, state: &state)
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Auth
    
    private func handleAuthNavigation(action: AuthFeature.Action, state: inout State) -> Effect<Action> {
        // Also make necessary changes to delegate actions in AppFeature
        switch action {
        case .delegate(.loginSuccess(_, _)):
            fatalError("Auth navigation must be handled in ProfileFlow enum reducer")
            
        case .delegate(.showSettings):
            state.path.append(.settings(.settings(SettingsFeature.State())))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Deeplinks
    
    enum DeeplinkHandlingError: Error {
        case failedToParseSamePagePost
        case unknownGoToType(GoTo)
    }
    
    private func handleDeeplink(url: URL, state: inout State) -> Effect<Action> {
        var url = url
        
        if url.absoluteString.prefix(7) == "link://" {
            return .run { [url] _ in
                let resultUrl = await DeeplinkHandler().handleInnerToOuterURL(url)
                await open(url: resultUrl)
            }
        }
        
        if url.scheme == "snapback" {
            if case let .forum(.topic(topic)) = state.path.last {
                url = URL(string: url.absoluteString + "/\(topic.topicId)")!
            }
        }
        
        do {
            let deeplink = try DeeplinkHandler().handleInnerToInnerURL(url)
            switch deeplink {
            case let .topic(id: targetId, goTo: goTo):
                if let targetId {
                    // Deeplink in the same OR other topic
                    if let (id, element) = state.path.last(is: \.forum.topic), let topicId = element.forum?.topic?.topicId, topicId == targetId {
                        if case let .post(goToId) = goTo {
                            guard let hasPostOnTheSamePage = element.forum?.topic?.topic?.posts.map({ $0.id }).contains(goToId) else {
                                analytics.capture(DeeplinkHandlingError.failedToParseSamePagePost)
                                return .none
                            }
                            if hasPostOnTheSamePage {
                                // Post is on the same page, scrolling to
                                // TODO: send goTo via action or state?
                                state.path[id: id, case: \.forum.topic]?.goTo = goTo
                                return reduce(into: &state, action: .path(.element(id: id, action: .forum(.topic(.internal(.load))))))
                            } else {
                                // Post is NOT on the same page, opening new screen
                                state.path.append(.forum(.topic(TopicFeature.State(topicId: targetId, goTo: goTo))))
                                return .none
                            }
                        } else {
                            analytics.capture(DeeplinkHandlingError.unknownGoToType(goTo))
                            return .none
                        }
                    }
                    
                    // Different topic or announcement, using app navigation
                    state.path.append(.forum(.topic(TopicFeature.State(topicId: targetId, goTo: goTo))))
                } else {
                    // Deeplink in the same topic ONLY (inner-inner deeplink case)
                    if let (id, _) = state.path.last(is: \.forum.topic) {
                        state.path[id: id, case: \.forum.topic]?.goTo = goTo
                        return reduce(into: &state, action: .path(.element(id: id, action: .forum(.topic(.internal(.load))))))
                    }
                }
                
            case let .forum(id: id, page: page):
                state.path.append(.forum(.forum(ForumFeature.State(forumId: id, initialPage: page))))
                
            case let .announcement(id: id):
                state.path.append(.forum(.announcement(AnnouncementFeature.State(id: id))))
                
            case let .user(id: id):
                state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
                
            case let .qms(id: id):
                state.path.append(.qms(.qms(QMSFeature.State(chatId: id))))
                
            case let .article(id: id, title: title, imageUrl: imageUrl):
                let preview = ArticlePreview.outerDeeplink(id: id, imageUrl: imageUrl, title: title)
                state.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
            }
            
            return .none
        } catch {
            if case .externalURL = error {
                // Skipping externalURL case since it's not error per-se
            } else {
                analytics.capture(error)
            }
        }
        
        return .run { [url] _ in await open(url: url) }
    }
}

extension StackState<Path.State> {
    func last(is keyPath: PartialCaseKeyPath<Path.State>) -> (StackElementID, Path.State)? {
        guard let (id, element) = Array(zip(ids, self)).last else { return nil }
        guard element.is(keyPath) else { return nil }
        return (id, element)
    }
}
