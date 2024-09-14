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
    }
    
    @Reducer(state: .equatable)
    public enum BookmarksPath {
        
    }
    
    @Reducer(state: .equatable)
    public enum ForumPath {
        
    }
    
    @Reducer(state: .equatable)
    public enum ProfilePath {
        case auth(AuthFeature)
        case profile(ProfileFeature)
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
        public var profile: MenuFeature.State
        
        public var selectedTab: AppView.Tab
        public var showToast: Bool
        public var toast: ToastInfo
        public var localizationBundle: Bundle? {
            switch toast.screen {
            case .articlesList: return Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticlesListFeature") })
            case .article:      return Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticleFeature") })
            }
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
            profile: MenuFeature.State = MenuFeature.State(),
            selectedTab: AppView.Tab = .articlesList,
            showToast: Bool = false,
            toast: ToastInfo = ToastInfo(screen: .articlesList, message: String(""))
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
            
            self.selectedTab = selectedTab
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
        case profile(MenuFeature.Action)
        
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
            MenuFeature()
        }
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Common
                
            case .appDelegate, .binding:
                return .none
                
            case let .didSelectTab(tab):
                if state.selectedTab == tab {
                    if tab == .articlesList, state.articlesPath.isEmpty {
                        state.articlesList.scrollToTop.toggle()
                    }
                } else {
                    state.selectedTab = tab
                }
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
                    guard let url            = urlComponents.url                      else { fatalError() }
                    guard let titleEncoded   = urlComponents.queryItems?.first?.value else { fatalError() }
                    guard let title          = titleEncoded.removingPercentEncoding   else { fatalError() }
                    guard let imageUrlString = urlComponents.queryItems?[1].value     else { fatalError() }
                    guard let imageUrl       = URL(string: imageUrlString)            else { fatalError() }
                    
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
        
        // MARK: - Article Path
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Articles List
                
            case let .articlesList(.articleTapped(articlePreview)):
                state.articlesPath.append(.article(ArticleFeature.State(articlePreview: articlePreview)))
                return .none
                
            case let .articlesList(.cellMenuOpened(_, action)):
                switch action {
                case .copyLink, .report:
                    state.toast = ToastInfo(screen: .articlesList, message: action.rawValue)
                case .shareLink, .openInBrowser, .addToBookmarks:
                    return .none
                }
                state.showToast = true
                return .none
                
            case .articlesList(.settingsButtonTapped):
                state.selectedTab = .profile
                if case .settings = state.profilePath.last {
                    // Last screen is already settings
                } else {
                    state.profilePath.append(.settings(SettingsFeature.State()))
                }
                return .none
                
            case .articlesList:
                return .none
                
                // MARK: Article
                
            case let .articlesPath(.element(id: _, action: .article(.menuActionTapped(action)))):
                switch action {
                case .copyLink, .report:
                    state.toast = ToastInfo(screen: .article, message: action.rawValue)
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
                
            default:
                return .none
            }
        }
        .forEach(\.articlesPath, action: \.articlesPath)
        
        // MARK: - Bookmarks Path
        
        Reduce { state, action in
            switch action {
            case .bookmarks(.settingsButtonTapped):
                state.selectedTab = .profile
                if case .settings = state.profilePath.last {
                    // Last screen is already settings
                } else {
                    state.profilePath.append(.settings(SettingsFeature.State()))
                }
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.bookmarksPath, action: \.bookmarksPath)
        
        // MARK: - Forum Path
        
        Reduce { state, action in
            switch action {
            case .forum(.settingsButtonTapped):
                state.selectedTab = .profile
                if case .settings = state.profilePath.last {
                    // Last screen is already settings
                } else {
                    state.profilePath.append(.settings(SettingsFeature.State()))
                }
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.forumPath, action: \.forumPath)
        
        // MARK: - Profile Path
        
        Reduce { state, action in
            switch action {
                
                // MARK: Menu
                
            case .profile(.delegate(.openAuth)):
                state.profilePath.append(.auth(AuthFeature.State()))
                return .none
                
            case let .profile(.delegate(.openProfile(id: id))):
                state.profilePath.append(.profile(ProfileFeature.State(userId: id)))
                return .none
                
            case .profile(.settingsTapped):
                state.profilePath.append(.settings(SettingsFeature.State()))
                return .none
                
                // MARK: Auth
                
            case let .profilePath(.element(id: id, action: .auth(.delegate(.loginSuccess(userId: userId))))):
                // TODO: How to make seamless animation?
                state.profilePath.pop(from: id)
                state.profilePath.append(.profile(ProfileFeature.State(userId: userId)))
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.profilePath, action: \.profilePath)
    }
}
