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
import TCAExtensions

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
        public var isRefreshing = false
        
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
        case onAppear
        case onRefresh
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
            case .onAppear:
                guard state.favorites.isEmpty && state.favoritesImportant.isEmpty else { return .none }
                return .send(._loadFavorites(unreadFirst: false, offset: 0))
                
            case .onRefresh:
                state.isRefreshing = true
                return .run { send in
                    await send(._loadFavorites(unreadFirst: false, offset: 0))
                }
                
            case let .pageNavigation(.offsetChanged(to: newOffset)):
                return .send(._loadFavorites(unreadFirst: false, offset: newOffset))
                
            case .pageNavigation:
                return .none
                
            case .settingsButtonTapped, .favoriteTapped(_, _, _):
                return .none
                
            case let ._loadFavorites(unreadFirst, offset):
                if !state.isRefreshing {
                    state.isLoading = true
                }
                return .run { [perPage = state.appSettings.forumPerPage, isRefreshing = state.isRefreshing] send in
                    let startTime = Date()
                    for try await favorites in try await apiClient.getFavorites(
                        unreadFirst: unreadFirst,
                        offset: offset,
                        perPage: perPage,
                        policy: isRefreshing ? .skipCache : .cacheAndLoad
                    ) {
                        if isRefreshing { await delayUntilTimePassed(1.0, since: startTime) }
                        await send(._favoritesResponse(.success(favorites)))
                    }
                } catch: { error, send in
                    await send(._favoritesResponse(.failure(error)))
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
                state.isRefreshing = false
                
                return .none
                
            case let ._favoritesResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}
