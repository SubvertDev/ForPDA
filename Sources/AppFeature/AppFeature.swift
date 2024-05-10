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

@Reducer
public struct AppFeature {
    
    public init() {}
    
    // MARK: - Path
    
    @Reducer(state: .equatable)
    public enum Path {
        case menu(MenuFeature)
        case news(NewsFeature)
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
                
            case .path:
                return .none
                
            case .newsList(.menuTapped):
                state.path.append(.menu(MenuFeature.State()))
                return .none
                
            case let .newsList(.newsTapped(id)):
                print(id)
                state.path.append(.news(NewsFeature.State(news: .mock)))
                return .none
                
            case .newsList:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}
