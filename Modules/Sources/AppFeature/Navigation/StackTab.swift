//
//  StackTab.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 30.03.2025.
//

import Foundation
import ComposableArchitecture
import ArticleFeature
import SettingsFeature
import NotificationsFeature
import DeveloperFeature
import ForumFeature
import TopicFeature
import FavoritesRootFeature
import ProfileFeature
import Models
import AnnouncementFeature
import HistoryFeature
import QMSListFeature
import QMSFeature

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
        }
    }
    
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
                state.showTabBar = !hasArticle && !hasSettings && !hasQms
                return .send(.delegate(.showTabBar(state.showTabBar)))
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
        }
    }
    
    // MARK: - Articles
    
    private func handleArticlesPathNavigation(action: Path.Articles.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .articlesList(.delegate(.openArticle(preview))):
            state.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
            
        case .articlesList(.delegate(.openSettings)):
            state.path.append(.settings(.settings(SettingsFeature.State())))
            
        case let .article(.delegate(.handleDeeplink(id))):
            #warning("handle deeplink in another place?")
            let preview = ArticlePreview.innerDeeplink(id: id)
            state.path.append(.articles(.article(ArticleFeature.State(articlePreview: preview))))
            
        case let .article(.delegate(.commentHeaderTapped(id))):
            state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
            
        case let .article(.comments(.element(id: _, action: .profileTapped(userId: id)))):
            #warning("what's the difference between these two?")
            state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Favorites
    
    private func handleFavoritesPathNavigation(action: FavoritesRootFeature.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .favorites(.delegate(.openForum(id: id, name: name))):
            state.path.append(.forum(.forum(ForumFeature.State(forumId: id, forumName: name))))
            
        case let .favorites(.delegate(.openTopic(id: id, name: name, offset: offset, postId: postId))):
            state.path.append(.forum(.topic(TopicFeature.State(topicId: id, topicName: name, initialOffset: offset, postId: postId))))
            
        case .delegate(.openSettings):
            state.path.append(.settings(.settings(SettingsFeature.State())))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Forum
    
    private func handleForumPathNavigation(action: Path.Forum.Action, state: inout State) -> Effect<Action> {
        switch action {
        case .forumList(.delegate(.openSettings)):
            state.path.append(.settings(.settings(SettingsFeature.State())))
            
        case let .forumList(.delegate(.openForum(id: id, name: name))):
            state.path.append(.forum(.forum(ForumFeature.State(forumId: id, forumName: name))))
            
        case let .forumList(.delegate(.handleForumRedirect(url))):
            return handleDeeplink(url: url, state: &state)
            
        case let .forum(.announcementTapped(id: id, name: name)):
            state.path.append(.forum(.announcement(AnnouncementFeature.State(id: id, name: name))))
            
        case let .forum(.subforumTapped(id: id, name: name)):
            #warning("make id/name")
            state.path.append(.forum(.forum(ForumFeature.State(forumId: id, forumName: name))))
            
        case let .forum(.subforumRedirectTapped(url)):
            return handleDeeplink(url: url, state: &state)
            
        case let .forum(.topicTapped(id: id, offset: offset)):
            #warning("add name to parameters + localization")
            state.path.append(.forum(.topic(TopicFeature.State(topicId: id, topicName: "Загружаем..", initialOffset: offset))))
            
        case let .announcement(.urlTapped(url)):
            #warning("make delegate actions")
            return handleDeeplink(url: url, state: &state)
            
        case let .topic(.urlTapped(url)):
            #warning("make delegate actions")
            return handleDeeplink(url: url, state: &state)
            
        case let .topic(.userAvatarTapped(id)):
            #warning("make delegate actions")
            state.path.append(.profile(.profile(ProfileFeature.State(userId: id))))
            
        case let .topic(._topicResponse(.failure)):
            #warning("make delegate actions")
            state.path.removeLast()
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Profile
    
    private func handleProfilePathNavigation(action: Path.Profile.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .profile(.historyButtonTapped):
            #warning("make delegate")
            state.path.append(.profile(.history(HistoryFeature.State())))
            
        case .profile(.qmsButtonTapped):
            #warning("make delegate")
            state.path.append(.qms(.qmsList(QMSListFeature.State())))
            
        case .profile(.settingsButtonTapped):
            #warning("make delegate")
            state.path.append(.settings(.settings(SettingsFeature.State())))
            
        case let .profile(.deeplinkTapped(url, _)):
            #warning("make delegate")
            return handleDeeplink(url: url, state: &state)
            
        case let .history(.topicTapped(id: id)):
            #warning("add name to parameters + localization")
            state.path.append(.forum(.topic(TopicFeature.State(topicId: id, topicName: "Загружаем.."))))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - Settings
    
    private func handleSettingsPathNavigation(action: Path.Settings.Action, state: inout State) -> Effect<Action> {
        switch action {
        case .settings(.notificationsButtonTapped):
            #warning("make delegate")
            state.path.append(.settings(.notifications(NotificationsFeature.State())))
            
        case .settings(.onDeveloperMenuTapped):
            #warning("make delegate")
            state.path.append(.settings(.developer(DeveloperFeature.State())))
            
        default:
            break
        }
        return .none
    }
    
    // MARK: - QMS
    
    private func handleQMSPathNavigation(action: Path.QMS.Action, state: inout State) -> Effect<Action> {
        switch action {
        case let .qmsList(.chatRowTapped(id)):
            state.path.append(.qms(.qms(QMSFeature.State(chatId: id))))
            
        default:
            break
        }
        return .none
    }
    
    #warning("different object for deeplink handling?")
    private func handleDeeplink(url: URL, state: inout State) -> Effect<Action> {
        return .none
    //        if url.absoluteString.prefix(7) == "link://" {
    //            return .run { _ in
    //                let resultUrl = await DeeplinkHandler().handleInnerToOuterURL(url)
    //                await open(url: resultUrl)
    //            }
    //        }
    //        do {
    //            if let deeplink = try DeeplinkHandler().handleInnerToInnerURL(url),
    //                case let .forum(screen) = deeplink.tab {
    //
    //                if state.selectedTab == .favorites {
    //                    switch screen {
    //                    case let .forum(id: id):
    //                        state.favoritesRootPath.append(.forumPath(.forum(ForumFeature.State(forumId: id, forumName: nil))))
    //
    //                    case let .topic(id: id):
    //                        state.favoritesRootPath.append(.forumPath(.topic(TopicFeature.State(topicId: id))))
    //
    //
    //                    case let .announcement(id: id):
    //                        state.favoritesRootPath.append(.forumPath(.announcement(AnnouncementFeature.State(id: id, name: nil))))
    //                    }
    //                }
    //
    //                if state.selectedTab == .forum {
    //                    switch screen {
    //                    case let .forum(id: id):
    //                        state.forumPath.append(.forum(ForumFeature.State(forumId: id, forumName: nil)))
    //
    //                    case let .topic(id: id):
    //                        state.forumPath.append(.topic(TopicFeature.State(topicId: id)))
    //
    //                    case let .announcement(id: id):
    //                        state.forumPath.append(.announcement(AnnouncementFeature.State(id: id, name: nil)))
    //                    }
    //                }
    //
    //                if state.selectedTab == .profile {
    //                    switch screen {
    //                    case let .topic(id: id):
    //                        state.forumPath.append(.topic(TopicFeature.State(topicId: id)))
    //                        state.selectedTab = .forum
    //
    //                    default: return .none
    //                    }
    //                }
    //                return .none
    //            }
    //        } catch {
    //            analyticsClient.capture(error)
    //        }
    //        return .run { _ in await open(url: url) }
    }
}
