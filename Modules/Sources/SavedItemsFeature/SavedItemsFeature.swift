//
//  SavedItemsFeature.swift
//  APIClient
//
//  Created by Рустам Ойтов on 25.02.2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture


@Reducer
public struct SavedItemsFeature: Reducer {
    
    @ObservableState
    public struct State: Equatable {
        var favorites = FavoritesFeature.State()
        var bookmarks = BookmarksFeature.State() 
    }
    
    public enum Action {
        case favorites(FavoritesFeature.Action)
        case bookmarks(BookmarksFeature.Action)
    }
    
    public var body: some Reduce<State, Action> {
        Scope(state: \.favorites, action: .case(SavedItemsFeature.Action.favorites)) {
            FavoritesFeature()
        }
        Scope(state: \.bookmarks, action: .case(SavedItemsFeature.Action.bookmarks)) {
            BookmarksFeature()
        }
    }
    
}
