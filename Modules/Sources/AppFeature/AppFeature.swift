//
//  AppFeature.swift
//
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import SwiftUI
import ComposableArchitecture
import DeeplinkHandler
import ArticlesListFeature
import ArticleFeature
import BookmarksFeature
import ForumsListFeature
import ForumFeature
import TopicFeature
import AnnouncementFeature
import FavoritesRootFeature
import HistoryFeature
import AuthFeature
import ProfileFeature
import QMSListFeature
import QMSFeature
import SettingsFeature
import NotificationsFeature
import DeveloperFeature
import APIClient
import Models
import TCAExtensions
import BackgroundTasks
import LoggerClient
import NotificationsClient

@Reducer
public struct AppFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Paths
    
    @Reducer(state: .equatable)
    public enum ArticlesPath {
        case article(ArticleFeature)
        case profile(ProfileFeature)
        case settingsPath(SettingsPath.Body = SettingsPath.body)
    }
    
    @Reducer(state: .equatable)
    public enum FavoritesRootPath {
        case forumPath(ForumPath.Body = ForumPath.body)
        case settingsPath(SettingsPath.Body = SettingsPath.body)
    }
    
    @Reducer(state: .equatable)
    public enum ForumPath {
        case forum(ForumFeature)
        case announcement(AnnouncementFeature)
        case topic(TopicFeature)
        case profile(ProfileFeature)
        case settingsPath(SettingsPath.Body = SettingsPath.body)
    }
    
    @Reducer(state: .equatable)
    public enum ProfilePath {
        case history(HistoryFeature)
        case qmsPath(QMSPath.Body = QMSPath.body)
        case settingsPath(SettingsPath.Body = SettingsPath.body)
    }
    
    @Reducer(state: .equatable)
    public enum SettingsPath {
        case settings(SettingsFeature)
        case notifications(NotificationsFeature)
        case developer(DeveloperFeature)
    }
    
    @Reducer(state: .equatable)
    public enum QMSPath {
        case qmsList(QMSListFeature)
        case qms(QMSFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var appDelegate: AppDelegateFeature.State
        
        public var articlesPath: StackState<ArticlesPath.State>
        public var favoritesRootPath: StackState<FavoritesRootPath.State>
        public var forumPath: StackState<ForumPath.State>
        public var profilePath: StackState<ProfilePath.State>
        
        public var articlesList: ArticlesListFeature.State
        public var favoritesRoot: FavoritesRootFeature.State
        public var forumsList: ForumsListFeature.State
        public var profile: ProfileFeature.State
        
        @Presents public var auth: AuthFeature.State?
        @Presents public var alert: AlertState<Never>?
        
        @Shared(.userSession) public var userSession: UserSession?
        @Shared(.appSettings) public var appSettings: AppSettings
        
        public var selectedTab: AppTab
        public var previousTab: AppTab
        public var isShowingTabBar: Bool
        public var showToast: Bool // TODO: Refactor into Destination?
        public var toast: ToastInfo
        public var localizationBundle: Bundle {
            switch toast.screen {
            case .app:          return .module
            case .articlesList: return .articlesList
            case .article:      return .article
            case .comments:     return .models
            case .favorites:    return .favorites
            }
        }
        
        public var isAuthorized: Bool {
            return userSession != nil
        }
        
        public var notificationsId: String {
            let identifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String]
            return identifiers?.first ?? ""
        }
        
        public init(
            appDelegate: AppDelegateFeature.State = AppDelegateFeature.State(),
            articlesPath: StackState<ArticlesPath.State> = StackState(),
            favoritesRootPath: StackState<FavoritesRootPath.State> = StackState(),
            forumPath: StackState<ForumPath.State> = StackState(),
            profilePath: StackState<ProfilePath.State> = StackState(),
            articlesList: ArticlesListFeature.State = ArticlesListFeature.State(),
            favoritesRoot: FavoritesRootFeature.State = FavoritesRootFeature.State(),
            forumsList: ForumsListFeature.State = ForumsListFeature.State(),
            profile: ProfileFeature.State = ProfileFeature.State(),
            auth: AuthFeature.State? = nil,
            alert: AlertState<Never>? = nil,
            selectedTab: AppTab = .articlesList,
            previousTab: AppTab = .articlesList,
            isShowingTabBar: Bool = true,
            showToast: Bool = false,
            toast: ToastInfo = ToastInfo(screen: .articlesList, message: String(""), isError: false)
        ) {
            self.appDelegate = appDelegate
            
            self.articlesPath = articlesPath
            self.favoritesRootPath = favoritesRootPath
            self.forumPath = forumPath
            self.profilePath = profilePath
            
            self.articlesList = articlesList
            self.favoritesRoot = favoritesRoot
            self.forumsList = forumsList
            self.profile = profile
            
            self.auth = auth
            self.alert = alert
            
            self.selectedTab = selectedTab
            self.previousTab = previousTab
            self.isShowingTabBar = isShowingTabBar
            self.showToast = showToast
            self.toast = toast
            
            self.selectedTab = _appSettings.startPage.wrappedValue
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case onAppear
        
        case appDelegate(AppDelegateFeature.Action)
        
        case articlesPath(StackActionOf<ArticlesPath>)
        case favoritesRootPath(StackActionOf<FavoritesRootPath>)
        case forumPath(StackActionOf<ForumPath>)
        case profilePath(StackActionOf<ProfilePath>)
        
        case articlesList(ArticlesListFeature.Action)
        case favoritesRoot(FavoritesRootFeature.Action)
        case forumsList(ForumsListFeature.Action)
        case profile(ProfileFeature.Action)
        
        case auth(PresentationAction<AuthFeature.Action>)
        case alert(PresentationAction<Never>)
        
        case binding(BindingAction<State>) // For Toast
        case didSelectTab(AppTab)
        case deeplink(URL)
        case scenePhaseDidChange(from: ScenePhase, to: ScenePhase)
        case registerBackgroundTask
        case syncUnreadTaskInvoked
        case didFinishToastAnimation
        
        case _failedToConnect(any Error)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.logger[.app])         private var logger
    @Dependency(\.apiClient)            private var apiClient
    @Dependency(\.cacheClient)          private var cacheClient
    @Dependency(\.hapticClient)         private var hapticClient
    @Dependency(\.analyticsClient)      private var analyticsClient
    @Dependency(\.notificationsClient)  private var notificationsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateFeature()
        }
        
        Scope(state: \.articlesList, action: \.articlesList) {
            ArticlesListFeature()
        }
        
        Scope(state: \.favoritesRoot, action: \.favoritesRoot) {
            FavoritesRootFeature()
        }
        
        Scope(state: \.forumsList, action: \.forumsList) {
            ForumsListFeature()
        }
        
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Common
                
            case .onAppear:
                return .run { send in
                    do {
                        await apiClient.setLogResponses(.none)
                        try await apiClient.connect()
                    } catch {
                        await send(._failedToConnect(error))
                    }
                }
                
            case .didFinishToastAnimation:
                state.showToast = false
                return .none
                
            case ._failedToConnect:
                state.alert = .failedToConnect
                return .none
                
            case .appDelegate, .binding, .alert:
                return .none
                
            case let .didSelectTab(tab):
                if state.selectedTab == tab {
                    if tab == .articlesList, state.articlesPath.isEmpty {
                        state.articlesList.scrollToTop.toggle() // TODO: Not working anymore
                    }
                } else {
                    if tab == .profile && !state.isAuthorized {
                        state.auth = AuthFeature.State(openReason: .profile)
                        // Opening tab only after auth via delegate action
                    } else {
                        state.previousTab = state.selectedTab
                        state.selectedTab = tab
                    }
                }
                
                // Updating favorites on tab selection
                if state.selectedTab == .favorites && state.previousTab != .favorites {
                    return FavoritesRootFeature()
                        .reduce(into: &state.favoritesRoot, action: .favorites(.onRefresh))
                        .map(Action.favoritesRoot)
                }
                return .none
                
            case let .auth(.presented(.delegate(.loginSuccess(reason, _)))):
                state.auth = nil
                if reason == .profile {
                    state.previousTab = state.selectedTab
                    state.selectedTab = .profile
                }
                return .none
                
            case .auth:
                return .none
                
                // MARK: - Deeplink
                
            case .deeplink(let url):
                do {
                    let deeplink = try DeeplinkHandler().handleOuterToInnerURL(url)
                    switch deeplink.tab {
                    case let .articles(.article(id, title, imageUrl)):
                        let preview = ArticlePreview.outerDeeplink(id: id, imageUrl: imageUrl, title: title)
                        state.articlesPath.append(.article(ArticleFeature.State(articlePreview: preview)))
                        
                    default:
                        // TODO: Add other handlers later
                        break
                    }
                } catch {
                    analyticsClient.capture(error)
                    // TODO: Show error in UI?
                }
                return .none
                
                // MARK: - ScenePhase
                
            case let .scenePhaseDidChange(from: _, to: newPhase):
                return .run { [isLoggedIn = state.userSession != nil] send in
                    if newPhase == .background {
                        await send(.registerBackgroundTask)
                    }
                    if isLoggedIn {
                        await send(.syncUnreadTaskInvoked)
                    }
                }
                
            case .registerBackgroundTask:
                // return .send(.syncUnreadTaskInvoked) // For test purposes
                let request = BGAppRefreshTaskRequest(identifier: state.notificationsId)
                do {
                    try BGTaskScheduler.shared.submit(request)
                    logger.info("Successfully scheduled BGAppRefreshTaskRequest")
                    // Set breakpoint here and run:
                    // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.subvert.forpda.background.notifications"]
                } catch {
                    analyticsClient.capture(error)
                }
                return .none
                
            case .syncUnreadTaskInvoked:
                return .run { [appSettings = state.appSettings] send in
                    do {
                        guard try await notificationsClient.hasPermission() else { return }
                        guard appSettings.notifications.isAnyEnabled else { return }
                        
                        // try await apiClient.connect() // TODO: Do I need this?
                        let unread = try await apiClient.getUnread()
                        await notificationsClient.showUnreadNotifications(unread)
                        
                        // TODO: Make at an array?
                        let invokeTime = Date().timeIntervalSince1970
                        await cacheClient.setLastBackgroundTaskInvokeTime(invokeTime)
                    } catch {
                        analyticsClient.capture(error)
                    }
                    
                    await send(.registerBackgroundTask)
                }
                
                // MARK: - Default
                
            case .articlesList, .forumsList, .profile, .favoritesRoot:
                return .none
                
            case .articlesPath, .forumPath, .profilePath, .favoritesRootPath:
                return .none
                
            }
        }
        .ifLet(\.$auth, action: \.auth) {
            AuthFeature()
        }
        
        // MARK: - Article Path
        
        Reduce<State, Action> { state, action in
            switch action {
                
                // MARK: - Articles List
                
            case let .articlesList(.articleTapped(articlePreview)):
                state.articlesPath.append(.article(ArticleFeature.State(articlePreview: articlePreview)))
                return .none
                
            case let .articlesList(.cellMenuOpened(_, action)):
                switch action {
                case .copyLink, .report:
                    state.toast = ToastInfo(screen: .articlesList, message: action.rawValue, isError: false)
                case .shareLink, .openInBrowser, .addToBookmarks:
                    return .none
                }
                state.showToast = true
                return .none
                
            case .articlesList(.settingsButtonTapped):
                state.articlesPath.append(.settingsPath(.settings(SettingsFeature.State())))
                return .none
                
            case .articlesList:
                return .none
                
                // MARK: Article
                
            case let .articlesPath(.element(id: _, action: .article(.menuActionTapped(action)))):
                switch action {
                case .copyLink, .report:
                    state.toast = ToastInfo(screen: .article, message: action.rawValue, isError: false)
                case .shareLink:
                    return .none
                }
                state.showToast = true
                return .none
                
            case let .articlesPath(.element(id: _, action: .article(.delegate(.handleDeeplink(id))))):
                let articlePreview = ArticlePreview.innerDeeplink(id: id)
                state.articlesPath.append(.article(ArticleFeature.State(articlePreview: articlePreview)))
                return .none
                
            case let .articlesPath(.element(id: _, action: .article(.delegate(.commentHeaderTapped(id))))):
                state.articlesPath.append(.profile(ProfileFeature.State(userId: id)))
                return .none
                
            case let .articlesPath(.element(id: _, action: .article(.delegate(.showToast(type))))):
                state.toast = ToastInfo(screen: .comments, message: type.description, isError: type.isError)
                state.showToast = true
                return .none
                
            case let .articlesPath(.element(id: _, action: .article(.comments(.element(_, action))))):
                switch action {
                case let .profileTapped(userId: userId):
                    state.articlesPath.append(.profile(ProfileFeature.State(userId: userId)))
                    
                case .likeButtonTapped, .hideButtonTapped, .reportButtonTapped, .replyButtonTapped:
                    if !state.isAuthorized {
                        state.auth = AuthFeature.State(openReason: .commentAction)
                    }
                    
                default:
                    break
                }
                return .none
                
            case .articlesPath(.element(id: _, action: .article(.sendCommentButtonTapped))):
                if !state.isAuthorized {
                    state.auth = AuthFeature.State(openReason: .sendComment)
                }
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.articlesPath, action: \.articlesPath)
        .onChange(of: \.articlesPath) { _, newValue in
            Reduce<State, Action> { state, _ in
                state.isShowingTabBar = newValue.count == 0
                return .none
            }
        }
        
        
        // MARK: - Favorites Root Path
        
        Reduce<State, Action> { state, action in
            switch action {
            case .favoritesRoot(.favorites(.settingsButtonTapped)),
                .favoritesRootPath(.element(id: _, action: .forumPath(.forum(.settingsButtonTapped)))):
                state.favoritesRootPath.append(.settingsPath(.settings(SettingsFeature.State())))
                
            case .favoritesRoot(.favorites(._favoritesResponse(.failure))):
                state.toast = ToastInfo(screen: .favorites, message: "Whoops, something went wrong..", isError: true)
                state.showToast = true
                return .run { _ in await hapticClient.play(type: .error) }
                
            case .favoritesRoot(.favorites(.favoriteTapped(let id, let name, let offset, let postId, let isForum))):
                let forumPath: FavoritesRootPath.State = isForum
                	? .forumPath(.forum(ForumFeature.State(forumId: id, forumName: name)))
                	: .forumPath(.topic(TopicFeature.State(topicId: id, initialOffset: offset, postId: postId)))
                state.favoritesRootPath.append(forumPath)
                
            case .favoritesRoot(.favorites(._jumpRequestFailed)):
                state.toast = ToastInfo(screen: .app, message: "Post not found", isError: true)
                state.showToast = true
                return .run { _ in
                    await hapticClient.play(type: .error)
                }
                
            case let .favoritesRootPath(.element(id: _, action: .forumPath(.topic(.urlTapped(url))))),
                let .favoritesRootPath(.element(id: _, action: .forumPath(.announcement(.urlTapped(url))))):
                return handleDeeplink(url: url, state: &state)
                
            case let .favoritesRootPath(.element(id: _, action: .forumPath(.topic(.userAvatarTapped(userId: userId))))):
                state.favoritesRootPath.append(.forumPath(.profile(ProfileFeature.State(userId: userId))))
                

            case .favoritesRootPath(.element(id: _, action: .forumPath(.topic(._topicResponse(.failure))))):
                state.toast = ToastInfo(screen: .favorites, message: "Whoops, something went wrong..", isError: true)
                state.showToast = true
                state.favoritesRootPath.removeLast()
                return .run { _ in await hapticClient.play(type: .error) }
                
            case let .favoritesRootPath(.element(id: _, action: .forumPath(.forum(.topicTapped(id: id, offset: offset))))):
                state.favoritesRootPath.append(.forumPath(.topic(TopicFeature.State(topicId: id, initialOffset: offset))))
                
            case let .favoritesRootPath(.element(id: _, action: .forumPath(.forum(.announcementTapped(id: id, name: name))))):
                state.favoritesRootPath.append(.forumPath(.announcement(AnnouncementFeature.State(id: id, name: name))))
                
            case let .favoritesRootPath(.element(id: _, action: .forumPath(.forum(.subforumTapped(id: id, name: name))))):
                state.favoritesRootPath.append(.forumPath(.forum(ForumFeature.State(forumId: id, forumName: name))))
                
            default:
                break
            }
            return .none
        }
        .forEach(\.favoritesRootPath, action: \.favoritesRootPath)
        .onChange(of: \.favoritesRootPath) { _, newValue in
            Reduce<State, Action> { state, _ in
                state.isShowingTabBar = !newValue.contains {
                    if case .settingsPath = $0 { return true } else { return false }
                }
                return .none
            }
        }
        
        // MARK: - Forum Path
        
        Reduce<State, Action> { state, action in
            switch action {
            case .forumsList(.forumTapped(let forumId, let forumName)):
                state.forumPath.append(.forum(ForumFeature.State(forumId: forumId, forumName: forumName)))
                return .none
                
            case .forumsList(.forumRedirectTapped(let url)):
                return handleDeeplink(url: url, state: &state)
                
            case let .forumPath(.element(id: _, action: .forum(.subforumTapped(forumId, forumName)))):
                state.forumPath.append(.forum(ForumFeature.State(forumId: forumId, forumName: forumName)))
                return .none
                
            case let .forumPath(.element(id: _, action: .forum(.subforumRedirectTapped(url)))):
                return handleDeeplink(url: url, state: &state)
                
            case let .forumPath(.element(id: _, action: .forum(.announcementTapped(id, name)))):
                state.forumPath.append(.announcement(AnnouncementFeature.State(id: id, name: name)))
                return .none
                
            case let .forumPath(.element(id: _, action: .forum(.topicTapped(id: id, offset: offset)))):
                state.forumPath.append(.topic(TopicFeature.State(topicId: id, initialOffset: offset)))
                return .none
                
            case let .forumPath(.element(id: _, action: .topic(.userAvatarTapped(userId: userId)))):
                state.forumPath.append(.profile(ProfileFeature.State(userId: userId)))
                return .none
                
            case let .forumPath(.element(id: _, action: .profile(.deeplinkTapped(url, _)))):
                return handleDeeplink(url: url, state: &state)
                
            case .forumPath(.element(id: _, action: .topic(.urlTapped(let url)))),
                    .forumPath(.element(id: _, action: .announcement(.urlTapped(let url)))):
                return handleDeeplink(url: url, state: &state)
                
            case .forumsList(.settingsButtonTapped),
                    .forumPath(.element(id: _, action: .forum(.settingsButtonTapped))):
                state.forumPath.append(.settingsPath(.settings(SettingsFeature.State())))
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.forumPath, action: \.forumPath)
        .onChange(of: \.forumPath) { _, newValue in
            Reduce<State, Action> { state, _ in
                state.isShowingTabBar = !newValue.contains {
                    if case .settingsPath = $0 { return true } else { return false }
                }
                return .none
            }
        }
        
        // MARK: - Profile Path
        
        Reduce<State, Action> { state, action in
            switch action {
            case .profile(.qmsButtonTapped):
                state.profilePath.append(.qmsPath(.qmsList(QMSListFeature.State())))
                return .none
                
            case .profile(.settingsButtonTapped):
                state.profilePath.append(.settingsPath(.settings(SettingsFeature.State())))
                return .none
                
            case .profile(.logoutButtonTapped):
                state.selectedTab = .articlesList
                return .none
                
            case .profile(.historyButtonTapped):
                state.profilePath.append(.history(HistoryFeature.State()))
                return .none
                
            case .profile(.deeplinkTapped(let url, _)):
                return handleDeeplink(url: url, state: &state)
                
            case let .profilePath(.element(id: _, action: .history(.topicTapped(id)))):
                state.selectedTab = .forum
                state.forumPath.append(.topic(TopicFeature.State(topicId: id)))
                
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.profilePath, action: \.profilePath)
        .onChange(of: \.profilePath) { _, newValue in
            Reduce<State, Action> { state, _ in
                state.isShowingTabBar = !newValue.contains {
                    if case .qmsPath = $0 { return true }
                    if case .settingsPath = $0 { return true }
                    return false
                }
                return .none
            }
        }
        
        // MARK: - QMS Path
        
        Reduce<State, Action> { state, action in
            switch action {
            case let .profilePath(.element(id: _, action: .qmsPath(.qmsList(.chatRowTapped(chatId))))):
                state.profilePath.append(.qmsPath(.qms(QMSFeature.State(chatId: chatId))))
                return .none
                
            default:
                return .none
            }
        }
        
        // MARK: - Settings Path
        
        Reduce<State, Action> { state, action in
            switch action {
                
                // Notifications screen
                
            case .articlesPath(.element(id: _, action: .settingsPath(.settings(.notificationsButtonTapped)))):
                state.articlesPath.append(.settingsPath(.notifications(NotificationsFeature.State())))
                
            case .favoritesRootPath(.element(id: _, action: .settingsPath(.settings(.notificationsButtonTapped)))):
                state.favoritesRootPath.append(.settingsPath(.notifications(NotificationsFeature.State())))
                
            case .forumPath(.element(id: _, action: .settingsPath(.settings(.notificationsButtonTapped)))):
                state.forumPath.append(.settingsPath(.notifications(NotificationsFeature.State())))
                
            case .profilePath(.element(id: _, action: .settingsPath(.settings(.notificationsButtonTapped)))):
                state.profilePath.append(.settingsPath(.notifications(NotificationsFeature.State())))
                
                // Developer screen
                
            case .articlesPath(.element(id: _, action: .settingsPath(.settings(.onDeveloperMenuTapped)))):
                state.articlesPath.append(.settingsPath(.developer(DeveloperFeature.State())))
                
            case .favoritesRootPath(.element(id: _, action: .settingsPath(.settings(.onDeveloperMenuTapped)))):
                state.favoritesRootPath.append(.settingsPath(.developer(DeveloperFeature.State())))
                
            case .forumPath(.element(id: _, action: .settingsPath(.settings(.onDeveloperMenuTapped)))):
                state.forumPath.append(.settingsPath(.developer(DeveloperFeature.State())))
                
            case .profilePath(.element(id: _, action: .settingsPath(.settings(.onDeveloperMenuTapped)))):
                state.profilePath.append(.settingsPath(.developer(DeveloperFeature.State())))
                
            default:
                return .none
            }
            
            return .none
        }
    }
    
    private func handleDeeplink(url: URL, state: inout State) -> Effect<Action> {
        if url.absoluteString.prefix(7) == "link://" {
            return .run { _ in
                let resultUrl = await DeeplinkHandler().handleInnerToOuterURL(url)
                await open(url: resultUrl)
            }
        }
        do {
            if let deeplink = try DeeplinkHandler().handleInnerToInnerURL(url),
                case let .forum(screen) = deeplink.tab {
                
                if state.selectedTab == .favorites {
                    switch screen {
                    case let .forum(id: id):
                        state.favoritesRootPath.append(.forumPath(.forum(ForumFeature.State(forumId: id, forumName: nil))))
                        
                    case let .topic(id: id):
                        state.favoritesRootPath.append(.forumPath(.topic(TopicFeature.State(topicId: id))))
                        
                        
                    case let .announcement(id: id):
                        state.favoritesRootPath.append(.forumPath(.announcement(AnnouncementFeature.State(id: id, name: nil))))
                    }
                }
                
                if state.selectedTab == .forum {
                    switch screen {
                    case let .forum(id: id):
                        state.forumPath.append(.forum(ForumFeature.State(forumId: id, forumName: nil)))
                        
                    case let .topic(id: id):
                        state.forumPath.append(.topic(TopicFeature.State(topicId: id)))
                        
                    case let .announcement(id: id):
                        state.forumPath.append(.announcement(AnnouncementFeature.State(id: id, name: nil)))
                    }
                }
                
                if state.selectedTab == .profile {
                    switch screen {
                    case let .topic(id: id):
                        state.forumPath.append(.topic(TopicFeature.State(topicId: id)))
                        state.selectedTab = .forum
                        
                    default: return .none
                    }
                }
                return .none
            }
        } catch {
            analyticsClient.capture(error)
        }
        return .run { _ in await open(url: url) }
    }
}
