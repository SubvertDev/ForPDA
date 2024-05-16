//
//  AppFeature.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import ComposableArchitecture
import NewsListFeature
import NewsFeature
import MenuFeature
import SettingsFeature

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
        public var appDelegate = AppDelegateFeature.State()
        public var path = StackState<Path.State>()
        public var newsList = NewsListFeature.State()
        
        public init(
            newsList: NewsListFeature.State = NewsListFeature.State()
        ) {
            self.newsList = newsList
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case appDelegate(AppDelegateFeature.Action)
        case path(StackActionOf<Path>)
        case newsList(NewsListFeature.Action)
    }
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.appDelegate, action: \.appDelegate) {
            AppDelegateFeature()
        }
        
        Scope(state: \.newsList, action: \.newsList) {
            NewsListFeature()
        }
        
        Reduce { state, action in
            switch action {
            case .appDelegate:
                return .none
                
                // MARK: NewsList
                
            case .newsList(.menuTapped):
                state.path.append(.menu(MenuFeature.State()))
                return .none
                
            case let .newsList(.newsTapped(news)):
                state.path.append(.news(NewsFeature.State(news: news)))
                return .none
                
            case .newsList:
                return .none
                
                // MARK: Menu
                
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
