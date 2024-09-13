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
    public enum ForumPath {
        
    }
    
    @Reducer(state: .equatable)
    public enum MenuPath {
        case auth(AuthFeature)
        case profile(ProfileFeature)
        case settings(SettingsFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var appDelegate: AppDelegateFeature.State

        public var articlesPath: StackState<ArticlesPath.State>
        public var forumPath: StackState<ForumPath.State>
        public var menuPath: StackState<MenuPath.State>
        
        public var articlesList: ArticlesListFeature.State
        public var forum: ForumFeature.State
        public var menu: MenuFeature.State
        
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
            forumPath: StackState<ForumPath.State> = StackState(),
            menuPath: StackState<MenuPath.State> = StackState(),
            articlesList: ArticlesListFeature.State = ArticlesListFeature.State(),
            forum: ForumFeature.State = ForumFeature.State(),
            menu: MenuFeature.State = MenuFeature.State(),
            selectedTab: AppView.Tab = .articlesList,
            showToast: Bool = false,
            toast: ToastInfo = ToastInfo(screen: .articlesList, message: String(""))
        ) {
            self.appDelegate = appDelegate

            self.articlesPath = articlesPath
            self.forumPath = forumPath
            self.menuPath = menuPath
            
            self.articlesList = articlesList
            self.forum = forum
            self.menu = menu
            
            self.selectedTab = selectedTab
            self.showToast = showToast
            self.toast = toast
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case appDelegate(AppDelegateFeature.Action)

        case articlesPath(StackActionOf<ArticlesPath>)
        case forumPath(StackActionOf<ForumPath>)
        case menuPath(StackActionOf<MenuPath>)
        
        case articlesList(ArticlesListFeature.Action)
        case forum(ForumFeature.Action)
        case menu(MenuFeature.Action)
        
        case binding(BindingAction<State>) // For Toast
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
        
        Scope(state: \.forum, action: \.forum) {
            ForumFeature()
        }
        
        Scope(state: \.menu, action: \.menu) {
            MenuFeature()
        }
        
        Reduce { state, action in
            switch action {
                
                // MARK: - Common
                
            case .appDelegate, .binding:
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
                
            case .articlesList, .forum, .menu:
                return .none
                
            case .articlesPath, .forumPath, .menuPath:
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
                case .shareLink:
                    return .none
                }
                state.showToast = true
                return .none
                
            case .articlesList(.settingsButtonTapped):
                state.selectedTab = .profile
                if case .settings = state.menuPath.last {
                    // Last screen is already settings
                } else {
                    state.menuPath.append(.settings(SettingsFeature.State()))
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
        
        // MARK: - Forum Path
        
        Reduce { state, action in
            switch action {
            default:
                return .none
            }
        }
        .forEach(\.forumPath, action: \.forumPath)
        
        // MARK: - Menu Path
        
        Reduce { state, action in
            switch action {
                
                // MARK: Menu
                
            case .menu(.delegate(.openAuth)):
                state.menuPath.append(.auth(AuthFeature.State()))
                return .none
                
            case let .menu(.delegate(.openProfile(id: id))):
                state.menuPath.append(.profile(ProfileFeature.State(userId: id)))
                return .none
                
            case .menu(.settingsTapped):
                state.menuPath.append(.settings(SettingsFeature.State()))
                return .none
                
                // MARK: Auth
                
            case let .menuPath(.element(id: id, action: .auth(.delegate(.loginSuccess(userId: userId))))):
                // TODO: How to make seamless animation?
                state.menuPath.pop(from: id)
                state.menuPath.append(.profile(ProfileFeature.State(userId: userId)))
                return .none
                
            default:
                return .none
            }
        }
        .forEach(\.menuPath, action: \.menuPath)
    }
}
