//
//  FavoritesFeature.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation
import ComposableArchitecture
import PageNavigationFeature
import APIClient
import Models

@Reducer
public struct FavoritesFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        @Shared(.appSettings) var appSettings: AppSettings
        
        public var favorites: [FavoriteInfo] = []
        public var favoritesImportant: [FavoriteInfo] = []
        
        public var isLoading = false
        
        public var pageNavigation = PageNavigationFeature.State(type: .forum)
        
        public init(
            favorites: [FavoriteInfo] = [],
            favoritesImportant: [FavoriteInfo] = []
        ) {
            self.favorites = favorites
            self.favoritesImportant = favoritesImportant
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case settingsButtonTapped
        case favoriteTapped(id: Int, name: String, isForum: Bool)
        
        case pageNavigation(PageNavigationFeature.Action)
        
        case _favoritesResponse(Result<Favorite, any Error>)
        
        // TODO: Implement unreadFirst setting
        case _loadFavorites(unreadFirst: Bool = true, offset: Int)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                return .send(._loadFavorites(unreadFirst: true, offset: 0))
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                // TODO: Implement unreadFirst setting
                return .send(._loadFavorites(unreadFirst: true, offset: newOffset))
                
            case .pageNavigation:
                return .none
                
            case .settingsButtonTapped, .favoriteTapped(_, _, _):
                return .none
                
            case let ._loadFavorites(unreadFirst, offset):
                state.isLoading = true
                return .run { [perPage = state.appSettings.forumPerPage] send in
                    let result = await Result {
                        try await apiClient.getFavorites(unreadFirst: unreadFirst, offset: offset, perPage: perPage)
                    }
                    await send(._favoritesResponse(result))
                }
                
            case let ._favoritesResponse(.success(response)):
                var favsImportant: [FavoriteInfo] = []
                var favorites: [FavoriteInfo] = []

                for favorite in response.favorites {
                    if favorite.isImportant {
                        favsImportant.append(favorite)
                    } else {
                        favorites.append(favorite)
                    }
                }
                
                state.favoritesImportant = favsImportant
                state.favorites = favorites
                
                // TODO: Is it ok?
                state.pageNavigation.count = response.favoritesCount
                
                state.isLoading = false
                
                return .none
                
            case let ._favoritesResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}

