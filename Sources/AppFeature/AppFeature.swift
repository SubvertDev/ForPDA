//
//  AppFeature.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import Foundation
import ComposableArchitecture
import ArticlesListFeature
import NewsFeature
import MenuFeature
import SettingsFeature
import Models

@Reducer
public struct AppFeature {
    
    public init() {}
    
    // MARK: - Path
    
    @Reducer(state: .equatable)
    public enum Path {
        case news(NewsFeature)
        case menu(MenuFeature)
        case settings(SettingsFeature)
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var path: StackState<Path.State>
        public var appDelegate: AppDelegateFeature.State
        public var articlesList: ArticlesListFeature.State
        
        public var showToast: Bool
        public var toastMessage: String
        
        public init(
            path: StackState<Path.State> = StackState(),
            appDelegate: AppDelegateFeature.State = AppDelegateFeature.State(),
            articlesList: ArticlesListFeature.State = ArticlesListFeature.State(),
            showToast: Bool = false,
            toastMessage: String = ""
        ) {
            self.path = path
            self.appDelegate = appDelegate
            self.articlesList = articlesList
            self.showToast = showToast
            self.toastMessage = toastMessage
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case appDelegate(AppDelegateFeature.Action)
        case path(StackActionOf<Path>)
        case articlesList(ArticlesListFeature.Action)
        case binding(BindingAction<State>)
        case deeplink(URL)
    }
    
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
                    guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { fatalError() }
                    urlComponents.scheme = "https"
                    urlComponents.host =   "4pda.to"
                    
                    // RELEASE: Refactor. Add crashlytics?
                    guard let url            = urlComponents.url                      else { fatalError() }
                    guard let titleEncoded   = urlComponents.queryItems?.first?.value else { fatalError() }
                    guard let title          = titleEncoded.removingPercentEncoding   else { fatalError() }
                    guard let imageUrlString = urlComponents.queryItems?[1].value     else { fatalError() }
                    guard let imageUrl       = URL(string: imageUrlString)            else { fatalError() }
                    
                    let preview = NewsPreview(
                        url: url,
                        title: title,
                        description: "", // Not needed
                        imageUrl: imageUrl,
                        author: "", // Not needed
                        date: "", // Not needed
                        isReview: false,
                        commentAmount: "" // Not needed
                    )
                    let news = News(preview: preview)
                    state.path.append(.news(NewsFeature.State(news: news)))
                default: // For new deeplink usage cases
                    break
                }
                return .none
                
                // MARK: - NewsList
                
            case .articlesList(.menuTapped):
                state.path.append(.menu(MenuFeature.State()))
                return .none
                
            case let .articlesList(.articleTapped(article)):
                #warning("сделать переход")
//                state.path.append(.news(NewsFeature.State(news: news)))
                return .none
                
            case let .articlesList(.cellMenuOpened(_, action)):
                switch action {
                case .copyLink, .report:
                    state.toastMessage = action.rawValue.toString()
                case .shareLink:
                    return .none
                }
                state.showToast = true
                return .none
                
            case .articlesList:
                return .none
                
                // MARK: - News
                
            case let .path(.element(id: _, action: .news(.menuActionTapped(action)))):
                switch action {
                case .copyLink, .report:
                    state.toastMessage = action.rawValue.toString()
                case .shareLink:
                    return .none
                }
                state.showToast = true
                return .none
                
            case let .path(.element(id: _, action: .news(.delegate(.handleDeeplink(url))))):
                // RELEASE: Get the title? Move to deeplink section above?
                let preview = NewsPreview.deeplink(url: url)
                let news = News(preview: preview)
                state.path.append(.news(NewsFeature.State(news: news)))
                return .none
                
                // MARK: - Menu
                
            case .path(.element(id: _, action: .menu(.settingsTapped))):
                state.path.append(.settings(SettingsFeature.State()))
                return .none
                
            case .path:
                return .none
            }
            
        }
        .forEach(\.path, action: \.path)
    }
}
