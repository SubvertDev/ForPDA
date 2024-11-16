//
//  AppFeature.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import SwiftUI
import ComposableArchitecture
import ArticlesListFeature
import ArticleFeature
import BookmarksFeature
import ForumsListFeature
import ForumFeature
import TopicFeature
import FavoritesFeature
import MenuFeature
import AuthFeature
import ProfileFeature
import SettingsFeature
import APIClient
import Models
import TCAExtensions
import BackgroundTasks
import NotificationsClient

@Reducer
public struct AppFeature: Sendable {
    
    
    public init() {}
    
    // MARK: - Path
    
    @Reducer(state: .equatable)
    public enum ArticlesPath {
        case article(ArticleFeature)
        case profile(ProfileFeature)
        case settings(SettingsFeature)
    }
    
    @Reducer(state: .equatable)
    public enum BookmarksPath {
        case settings(SettingsFeature)
    }
    
    @Reducer(state: .equatable)
    public enum FavoritesPath {
        case settings(SettingsFeature)
    }
    
    @Reducer(state: .equatable)
    public enum ForumPath {
        case forum(ForumFeature)
        case topic(TopicFeature)
        case settings(SettingsFeature)
    }
    
    @Reducer(state: .equatable)
    public enum ProfilePath {
        case settings(SettingsFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var appDelegate: AppDelegateFeature.State

        public var articlesPath: StackState<ArticlesPath.State>
        // public var bookmarksPath: StackState<BookmarksPath.State>
        public var favoritesPath: StackState<FavoritesPath.State>
        public var forumPath: StackState<ForumPath.State>
        public var profilePath: StackState<ProfilePath.State>
        
        public var articlesList: ArticlesListFeature.State
        // public var bookmarks: BookmarksFeature.State
        public var favorites: FavoritesFeature.State
        public var forumsList: ForumsListFeature.State
        public var forum: ForumFeature.State
        public var profile: ProfileFeature.State
        
        @Presents public var auth: AuthFeature.State?
        @Presents public var alert: AlertState<Never>?
        
        @Shared(.userSession) public var userSession: UserSession?
        @Shared(.appSettings) public var appSettings: AppSettings
        
        public var selectedTab: AppTab
        public var previousTab: AppTab
        public var isShowingTabBar: Bool
        public var showToast: Bool
        public var toast: ToastInfo
        public var localizationBundle: Bundle? {
            switch toast.screen {
            case .articlesList: return Bundle.articlesListFeature
            case .article:      return Bundle.articleFeature
            case .comments:     return Bundle.models
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
            // bookmarksPath: StackState<BookmarksPath.State> = StackState(),
            favoritesPath: StackState<FavoritesPath.State> = StackState(),
            forumPath: StackState<ForumPath.State> = StackState(),
            menuPath: StackState<ProfilePath.State> = StackState(),
            articlesList: ArticlesListFeature.State = ArticlesListFeature.State(),
            // bookmarks: BookmarksFeature.State = BookmarksFeature.State(),
            favorites: FavoritesFeature.State = FavoritesFeature.State(),
            forumsList: ForumsListFeature.State = ForumsListFeature.State(),
            forum: ForumFeature.State = ForumFeature.State(forumId: 0, forumName: "Test"),
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
            // self.bookmarksPath = bookmarksPath
            self.favoritesPath = favoritesPath
            self.forumPath = forumPath
            self.profilePath = menuPath
            
            self.articlesList = articlesList
            // self.bookmarks = bookmarks
            self.favorites = favorites
            self.forumsList = forumsList
            self.forum = forum
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
        // case bookmarksPath(StackActionOf<BookmarksPath>)
        case favoritesPath(StackActionOf<FavoritesPath>)
        case forumPath(StackActionOf<ForumPath>)
        case profilePath(StackActionOf<ProfilePath>)
        
        case articlesList(ArticlesListFeature.Action)
        // case bookmarks(BookmarksFeature.Action)
        case favorites(FavoritesFeature.Action)
        case forumsList(ForumsListFeature.Action)
        case forum(ForumFeature.Action)
        case profile(ProfileFeature.Action)
        
        case auth(PresentationAction<AuthFeature.Action>)
        case alert(PresentationAction<Never>)
        
        case binding(BindingAction<State>) // For Toast
        case didSelectTab(AppTab)
        case deeplink(URL)
        case scenePhaseDidChange(from: ScenePhase, to: ScenePhase)
        case syncUnreadTaskInvoked
        
        case _failedToConnect(any Error)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.cacheClient) private var cacheClient
    @Dependency(\.analyticsClient) private var analyticsClient
    @Dependency(\.notificationsClient) private var notificationsClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateFeature()
        }
        
        Scope(state: \.articlesList, action: \.articlesList) {
            ArticlesListFeature()
        }
        
        // Scope(state: \.bookmarks, action: \.bookmarks) {
            // BookmarksFeature()
        // }
        
        Scope(state: \.favorites, action: \.favorites) {
            FavoritesFeature()
        }
        
        Scope(state: \.forumsList, action: \.forumsList) {
            ForumsListFeature()
        }
        
        Scope(state: \.forum, action: \.forum) {
            ForumFeature()
        }
        
        Scope(state: \.profile, action: \.profile) {
            ProfileFeature()
        }
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Common
                
            case .onAppear:
                return .run { send in
                    do {
                        await apiClient.setLogResponses(type: .none)
                        try await apiClient.connect()
                    } catch {
                        await send(._failedToConnect(error))
                    }
                }
                
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
                switch url.host {
                case "news":
                    // TODO: Make DeeplinkHandlerClient?
                    guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { fatalError() }
                    urlComponents.scheme = "https"
                    urlComponents.host =   "4pda.to"
                    
                    // TODO: Refactor. Add crashlytics?
                    let url            = urlComponents.url ?? URL(string: "/")!
                    let titleEncoded   = urlComponents.queryItems?.first?.value ?? ""
                    let title          = titleEncoded.removingPercentEncoding ?? ""
                    let imageUrlString = urlComponents.queryItems?[1].value
                    let imageUrl       = URL(string: imageUrlString ?? "/")!
                    
                    // TODO: Has duplicate in ArticleFeature
                    let regex = #//([\d]{6})//#
                    let match = url.absoluteString.firstMatch(of: regex)
                    let id = Int(match!.output.1)!
                    
                    let articlePreview = ArticlePreview.outerDeeplink(id: id, imageUrl: imageUrl, title: title)
                    state.articlesPath.append(.article(ArticleFeature.State(articlePreview: articlePreview)))
                    
                default: // For new deeplink usage cases
                    break
                }
                return .none
                
                // MARK: - ScenePhase
                
            case let .scenePhaseDidChange(from: _, to: newPhase):
                if newPhase == .background {
                    let request = BGAppRefreshTaskRequest(identifier: state.notificationsId)
                    do {
                        try BGTaskScheduler.shared.submit(request)
                        // Set breakpoint here and run:
                        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.subvert.forpda.background.notifications"]
                    } catch {
                        analyticsClient.capture(error)
                    }
                }
                return .none
                
            case .syncUnreadTaskInvoked:
                return .run { _ in
                    do {
                        // try await apiClient.connect()
                        let unread = try await apiClient.getUnread()
                        await notificationsClient.showUnreadNotifications(unread)
                        
                        let invokeTime = Date().timeIntervalSince1970
                        await cacheClient.setLastBackgroundTaskInvokeTime(invokeTime)
                    } catch {
                        analyticsClient.capture(error)
                    }
                }
                
                // MARK: - Default
                
            case .articlesList, .forumsList, .forum, .profile, .favorites:
                return .none
                
            case .articlesPath, .forumPath, .profilePath, .favoritesPath:
                return .none
            }
        }
        .ifLet(\.$auth, action: \.auth) {
            AuthFeature()
        }
        
        // MARK: - Article Path
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Articles List
                
            case let .articlesList(.articleTapped(articlePreview)):
                state.isShowingTabBar = false
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
                state.isShowingTabBar = false
                state.articlesPath.append(.settings(SettingsFeature.State()))
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
            // TODO: Another way?
            Reduce { state, _ in
                state.isShowingTabBar = newValue.count == 0
                // let hasSettings = newValue.contains(where: { screen in
                //     if case .settings = screen { return true }
                //     return false
                // })
                // state.isShowingTabBar = !hasSettings
                return .none
            }
        }
        
        // MARK: - Bookmarks Path
        
        // Reduce { state, action in
            // switch action {
            // case .bookmarks(.settingsButtonTapped):
                // state.isShowingTabBar = false
                // state.bookmarksPath.append(.settings(SettingsFeature.State()))
                // return .none
                //
            // default:
                // return .none
            // }
        // }
        // .forEach(\.bookmarksPath, action: \.bookmarksPath)
        // .onChange(of: \.bookmarksPath) { _, newValue in
            // // TODO: Another way?
            // Reduce { state, _ in
                // let hasSettings = newValue.contains(where: { screen in
                    // if case .settings = screen { return true }
                    // return false
                // })
                // state.isShowingTabBar = !hasSettings
                // return .none
            // }
        // }
        
        // MARK: - Favorites Path
        
        Reduce { state, action in
            switch action {
            case .favorites(.settingsButtonTapped):
                state.isShowingTabBar = false
                state.favoritesPath.append(.settings(SettingsFeature.State()))
                return .none

            case .favorites(.favoriteTapped(let id, let name, let isForum)):
                state.selectedTab = .forum
                if isForum {
                    state.forumPath.append(.forum(ForumFeature.State(forumId: id, forumName: name)))
                } else {
                    state.forumPath.append(.topic(TopicFeature.State(topicId: id)))
                }
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.favoritesPath, action: \.favoritesPath)
        .onChange(of: \.favoritesPath) { _, newValue in
            // TODO: Another way?
            Reduce { state, _ in
                let hasSettings = newValue.contains(where: { screen in
                    if case .settings = screen { return true }
                    return false
                })
                state.isShowingTabBar = !hasSettings
                return .none
            }
        }
        
        // MARK: - Forum Path
        
        Reduce { state, action in
            switch action {
            case .forumsList(.settingsButtonTapped),
                 .forumPath(.element(id: _, action: .forum(.settingsButtonTapped))):
                state.isShowingTabBar = false
                state.forumPath.append(.settings(SettingsFeature.State()))
                return .none
                
            case .forumsList(.forumTapped(let forumId, let forumName)):
                state.forumPath.append(.forum(ForumFeature.State(forumId: forumId, forumName: forumName)))
                return .none
                
            case let .forumPath(.element(id: _, action: .forum(.subforumTapped(forumId, forumName)))):
                state.forumPath.append(.forum(ForumFeature.State(forumId: forumId, forumName: forumName)))
                return .none
                
            case let .forumPath(.element(id: _, action: .forum(.topicTapped(id: id)))):
                state.forumPath.append(.topic(TopicFeature.State(topicId: id)))
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.forumPath, action: \.forumPath)
        .onChange(of: \.forumPath) { _, newValue in
            // TODO: Another way?
            Reduce { state, _ in
                let hasSettings = newValue.contains(where: { screen in
                    if case .settings = screen { return true }
                    return false
                })
                state.isShowingTabBar = !hasSettings
                return .none
            }
        }
        
        // MARK: - Profile Path
        
        Reduce { state, action in
            switch action {
                
            case .profile(.settingsButtonTapped):
                state.profilePath.append(.settings(SettingsFeature.State()))
                return .none
                
            case .profile(.logoutButtonTapped):
                state.selectedTab = .articlesList
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.profilePath, action: \.profilePath)
        .onChange(of: \.profilePath) { _, newValue in
            // TODO: Another way?
            Reduce { state, _ in
                let hasSettings = newValue.contains(where: { screen in
                    if case .settings = screen { return true }
                    return false
                })
                state.isShowingTabBar = !hasSettings
                return .none
            }
        }
    }
}

// MARK: - Extensions

extension Bundle {
    static var articlesListFeature: Bundle? {
        return Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticlesListFeature") })
    }
    
    static var articleFeature: Bundle? {
        Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticleFeature") })
    }
    
    static var models: Bundle? {
        Bundle.allBundles.first(where: { $0.bundlePath.contains("Models") })
    }
}
