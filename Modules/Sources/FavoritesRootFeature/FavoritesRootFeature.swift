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
    
    enum PickerSelection: Int {
        case favorites = 1
        case bookmarks = 2
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        var pickerSelection: PickerSelection = .favorites
        
        public var favorites: FavoritesFeature.State
        var bookmarks: BookmarksFeature.State
        
        public init(
            favorites: FavoritesFeature.State = FavoritesFeature.State(),
            bookmarks: BookmarksFeature.State = BookmarksFeature.State()
        ) {
            self.favorites = favorites
            self.bookmarks = bookmarks
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        
        case favorites(FavoritesFeature.Action)
        case bookmarks(BookmarksFeature.Action)
        
        case view(View)
        public enum View { }
        
        case delegate(Delegate)
        public enum Delegate { }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(state: \.favorites, action: \.favorites) {
            FavoritesFeature()
        }
        
        Scope(state: \.bookmarks, action: \.bookmarks) {
            BookmarksFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .favorites, .bookmarks, .delegate, .binding, .view:
                return .none
            }
        }
        
        Analytics()
    }
}
