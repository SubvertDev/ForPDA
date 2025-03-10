//
//  FavoritesRootFeature.swift
//  APIClient
//
//  Created by Рустам Ойтов on 01.03.2025.
//

import ComposableArchitecture
import FavoritesFeature
import BookmarksFeature

@Reducer
public struct FavoritesRootFeature: Reducer {
    
    public init() {}
    
    @ObservableState
    public struct State: Equatable {
        var favorites: FavoritesFeature.State
        var bookmarks: BookmarksFeature.State
        
        public init(
            favorites: FavoritesFeature.State = FavoritesFeature.State(),
            bookmarks: BookmarksFeature.State = BookmarksFeature.State()
        ) {
            self.favorites = favorites
            self.bookmarks = bookmarks
        }
    }
    
    public enum Action: ViewAction {
        case favorites(FavoritesFeature.Action)
        case bookmarks(BookmarksFeature.Action)
        
        case view(View)
        public enum View {
            case settingsButtonTapped
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case openSettings
        }
    }
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.favorites, action: \.favorites) {
            FavoritesFeature()
        }
        
        Scope(state: \.bookmarks, action: \.bookmarks) {
            BookmarksFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .favorites, .bookmarks:
                return .none
                
            case .view(.settingsButtonTapped):
                return .send(.delegate(.openSettings))
                
            case .delegate:
                return .none
            }
        }
    }
}
