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
import ForumFeature
import MenuFeature
import AuthFeature
import ProfileFeature
import SettingsFeature
import APIClient
import Models

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
    public enum ForumPath {
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
        public var bookmarksPath: StackState<BookmarksPath.State>
        public var forumPath: StackState<ForumPath.State>
        public var profilePath: StackState<ProfilePath.State>
        
        public var articlesList: ArticlesListFeature.State
        public var bookmarks: BookmarksFeature.State
        public var forum: ForumFeature.State
        public var profile: ProfileFeature.State
        
        @Presents public var auth: AuthFeature.State?
        
        @Shared(.userSession) public var userSession: UserSession?
        @Shared(.appSettings) public var appSettings: AppSettings
        public var selectedTab: AppView.Tab
        public var previousTab: AppView.Tab
        public var isShowingTabBar: Bool
        public var showToast: Bool
        public var toast: ToastInfo
        public var localizationBundle: Bundle? {
            switch toast.screen {
            case .articlesList: return Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticlesListFeature") })
            case .article:      return Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticleFeature") })
            case .comments:     return Bundle.allBundles.first(where: { $0.bundlePath.contains("Models") })
            }
        }
        
        public var isAuthorized: Bool {
            return userSession != nil
        }
        
        public init(
            appDelegate: AppDelegateFeature.State = AppDelegateFeature.State(),
            articlesPath: StackState<ArticlesPath.State> = StackState(),
            bookmarksPath: StackState<BookmarksPath.State> = StackState(),
            forumPath: StackState<ForumPath.State> = StackState(),
            menuPath: StackState<ProfilePath.State> = StackState(),
            articlesList: ArticlesListFeature.State = ArticlesListFeature.State(),
            bookmarks: BookmarksFeature.State = BookmarksFeature.State(),
            forum: ForumFeature.State = ForumFeature.State(),
            profile: ProfileFeature.State = ProfileFeature.State(),
            auth: AuthFeature.State? = nil,
            selectedTab: AppView.Tab = .articlesList,
            previousTab: AppView.Tab = .articlesList,
            isShowingTabBar: Bool = true,
            showToast: Bool = false,
            toast: ToastInfo = ToastInfo(screen: .articlesList, message: String(""), isError: false)
        ) {
            self.appDelegate = appDelegate

            self.articlesPath = articlesPath
            self.bookmarksPath = bookmarksPath
            self.forumPath = forumPath
            self.profilePath = menuPath
            
            self.articlesList = articlesList
            self.bookmarks = bookmarks
            self.forum = forum
            self.profile = profile
            
            self.auth = auth
            
            self.selectedTab = selectedTab
            self.previousTab = previousTab
            self.isShowingTabBar = isShowingTabBar
            self.showToast = showToast
            self.toast = toast
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case appDelegate(AppDelegateFeature.Action)

        case articlesPath(StackActionOf<ArticlesPath>)
        case bookmarksPath(StackActionOf<BookmarksPath>)
        case forumPath(StackActionOf<ForumPath>)
        case profilePath(StackActionOf<ProfilePath>)
        
        case articlesList(ArticlesListFeature.Action)
        case bookmarks(BookmarksFeature.Action)
        case forum(ForumFeature.Action)
        case profile(ProfileFeature.Action)
        
        case auth(PresentationAction<AuthFeature.Action>)
        
        case binding(BindingAction<State>) // For Toast
        case didSelectTab(AppView.Tab)
        case deeplink(URL)
        case scenePhaseDidChange(from: ScenePhase, to: ScenePhase)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateFeature()
        }
        
        Scope(state: \.articlesList, action: \.articlesList) {
            ArticlesListFeature()
        }
        
        Scope(state: \.bookmarks, action: \.bookmarks) {
            BookmarksFeature()
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
                
            case .appDelegate, .binding:
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
                
            case let .scenePhaseDidChange(from: from, to: to):
                if from == .background && to == .inactive {
                    return .run { _ in
                        // TODO: Check for notifications?
                    }
                } else {
                    return .none
                }
                
                // MARK: - Default
                
            case .articlesList, .bookmarks, .forum, .profile:
                return .none
                
            case .articlesPath, .bookmarksPath, .forumPath, .profilePath:
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
//                let hasSettings = newValue.contains(where: { screen in
//                    if case .settings = screen { return true }
//                    return false
//                })
//                state.isShowingTabBar = !hasSettings
                return .none
            }
        }
        
        // MARK: - Bookmarks Path
        
        Reduce { state, action in
            switch action {
            case .bookmarks(.settingsButtonTapped):
                state.isShowingTabBar = false
                state.bookmarksPath.append(.settings(SettingsFeature.State()))
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.bookmarksPath, action: \.bookmarksPath)
        .onChange(of: \.bookmarksPath) { _, newValue in
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
            case .forum(.settingsButtonTapped):
                state.isShowingTabBar = false
                state.forumPath.append(.settings(SettingsFeature.State()))
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
