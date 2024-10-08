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
    public enum Path {
        case article(ArticleFeature)
        case menu(MenuFeature)
        case auth(AuthFeature)
        case profile(ProfileFeature)
        case settings(SettingsFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var path: StackState<Path.State>
        public var appDelegate: AppDelegateFeature.State
        public var articlesList: ArticlesListFeature.State
        
        public var showToast: Bool
        public var toast: ToastInfo
        public var localizationBundle: Bundle? {
            switch toast.screen {
            case .articlesList: return Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticlesListFeature") })
            case .article:      return Bundle.allBundles.first(where: { $0.bundlePath.contains("ArticleFeature") })
            }
        }
        
        public init(
            path: StackState<Path.State> = StackState(),
            appDelegate: AppDelegateFeature.State = AppDelegateFeature.State(),
            articlesList: ArticlesListFeature.State = ArticlesListFeature.State(),
            showToast: Bool = false,
            toast: ToastInfo = ToastInfo(screen: .articlesList, message: "")
        ) {
            self.path = path
            self.appDelegate = appDelegate
            self.articlesList = articlesList
            self.showToast = showToast
            self.toast = toast
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case appDelegate(AppDelegateFeature.Action)
        case path(StackActionOf<Path>)
        case articlesList(ArticlesListFeature.Action)
        case binding(BindingAction<State>) // TODO: Do I need it?
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
                    state.path.append(.article(ArticleFeature.State(articlePreview: articlePreview)))
                    
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
                
                // MARK: - ArticlesList
                
            case .articlesList(.menuTapped):
                state.path.append(.menu(MenuFeature.State()))
                return .none
                
            case let .articlesList(.articleTapped(articlePreview)):
                state.path.append(.article(ArticleFeature.State(articlePreview: articlePreview)))
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
                
            case .articlesList:
                return .none
                
                // MARK: - Article
                
            case let .path(.element(id: _, action: .article(.menuActionTapped(action)))):
                switch action {
                case .copyLink, .report:
                    state.toast = ToastInfo(screen: .article, message: action.rawValue)
                case .shareLink:
                    return .none
                }
                state.showToast = true
                return .none
                
            case let .path(.element(id: _, action: .article(.delegate(.handleDeeplink(id))))):
                let articlePreview = ArticlePreview.innerDeeplink(id: id)
                state.path.append(.article(ArticleFeature.State(articlePreview: articlePreview)))
                return .none
                
            case let .path(.element(id: _, action: .article(.delegate(.commentHeaderTapped(id))))):
                state.path.append(.profile(ProfileFeature.State(userId: id)))
                return .none
                
                // MARK: - Menu
                
            case .path(.element(id: _, action: .menu(.delegate(.openAuth)))):
                state.path.append(.auth(AuthFeature.State()))
                return .none
                
            case let .path(.element(id: _, action: .menu(.delegate(.openProfile(id: id))))):
                state.path.append(.profile(ProfileFeature.State(userId: id)))
                return .none
                
            case .path(.element(id: _, action: .menu(.settingsTapped))):
                state.path.append(.settings(SettingsFeature.State()))
                return .none
                
                // MARK: - Auth
                
            case let .path(.element(id: id, action: .auth(.delegate(.loginSuccess(userId: userId))))):
                // TODO: How to make seamless animation?
                state.path.pop(from: id)
                state.path.append(.profile(ProfileFeature.State(userId: userId)))
                return .none
                
                // MARK: - Default
                
            case .path:
                return .none
            }
            
        }
        .forEach(\.path, action: \.path)
    }
}
