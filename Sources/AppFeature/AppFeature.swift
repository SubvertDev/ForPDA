//
//  AppFeature.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import Foundation
import ComposableArchitecture
import NewsListFeature
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
        public var newsList: NewsListFeature.State
        
        public var showToast: Bool
        public var toastMessage: String
        
        public init(
            path: StackState<Path.State> = StackState(),
            appDelegate: AppDelegateFeature.State = AppDelegateFeature.State(),
            newsList: NewsListFeature.State = NewsListFeature.State(),
            showToast: Bool = false,
            toastMessage: String = ""
        ) {
            self.path = path
            self.appDelegate = appDelegate
            self.newsList = newsList
            self.showToast = showToast
            self.toastMessage = toastMessage
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case appDelegate(AppDelegateFeature.Action)
        case path(StackActionOf<Path>)
        case newsList(NewsListFeature.Action)
        case binding(BindingAction<State>)
        case deeplink(URL)
    }
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        BindingReducer()
        
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateFeature()
        }
        
        Scope(state: \.newsList, action: \.newsList) {
            NewsListFeature()
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
                    
                    let news = NewsPreview(
                        url: url,
                        title: title,
                        description: "", // Not needed
                        imageUrl: imageUrl,
                        author: "", // Not needed
                        date: "", // Not needed
                        isReview: false,
                        commentAmount: "" // Not needed
                    )
                    state.path.append(.news(NewsFeature.State(news: news)))
                default: // For new deeplink usage cases
                    break
                }
                return .none
                
                // MARK: - NewsList
                
            case .newsList(.menuTapped):
                state.path.append(.menu(MenuFeature.State()))
                return .none
                
            case let .newsList(.newsTapped(news)):
                state.path.append(.news(NewsFeature.State(news: news)))
                return .none
                
            case let .newsList(.cellMenuOpened(_, action)):
                switch action {
                case .copyLink, .report:
                    state.toastMessage = action.rawValue.toString()
                case .shareLink:
                    return .none
                }
                state.showToast = true
                return .none
                
            case .newsList:
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
