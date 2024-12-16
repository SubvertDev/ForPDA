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
        
        case _favoritesResponse(Result<[FavoriteInfo], any Error>)
        
        case _loadFavorites(unreadFirst: Bool, offset: Int)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.pageNavigation, action: \.pageNavigation) {
            PageNavigationFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                return .send(._loadFavorites(unreadFirst: false, offset: 0))
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(._loadFavorites(unreadFirst: false, offset: newOffset))
                
            case .pageNavigation:
                return .none
                
            case .settingsButtonTapped, .favoriteTapped(_, _, _):
                return .none
                
            case let ._loadFavorites(unreadFirst, offset):
                state.isLoading = true
                return .run { [perPage = state.appSettings.forumPerPage] send in
                    do {
                        for try await favorites in try await apiClient.getFavorites(unreadFirst: unreadFirst, offset: offset, perPage: perPage) {
                            await send(._favoritesResponse(.success(favorites)))
                        }
                    } catch {
                        await send(._favoritesResponse(.failure(error)))
                    }
                }
                
            case let ._favoritesResponse(.success(response)):
                var favsImportant: [FavoriteInfo] = []
                var favorites: [FavoriteInfo] = []

                for favorite in response {
                    if favorite.isImportant {
                        favsImportant.append(favorite)
                    } else {
                        favorites.append(favorite)
                    }
                }
                
                state.favoritesImportant = favsImportant.sorted(by: { $0.topic.lastPost.date > $1.topic.lastPost.date })
                state.favorites = favorites.sorted(by: { $0.topic.lastPost.date > $1.topic.lastPost.date })
                
                // TODO: Is it ok?
                state.pageNavigation.count = response.count
                
                state.isLoading = false
                
                return .none
                
            case let ._favoritesResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}

