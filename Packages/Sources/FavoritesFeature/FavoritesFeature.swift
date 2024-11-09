//
//  FavoritesFeature.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation
import ComposableArchitecture
import APIClient
import Models

@Reducer
public struct FavoritesFeature: Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var favorites: [Favorite] = []
        public var favoritesImportant: [Favorite] = []
        
        public init(
            favorites: [Favorite] = [],
            favoritesImportant: [Favorite] = []
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
        
        case _favoritesResponse(Result<[Favorite], any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onTask:
                return .run { send in
                    // TODO: Implement unreadFirst and perPage.
                    let result = await Result { try await apiClient.getFavorites(unreadFirst: true, perPage: 10) }
                    await send(._favoritesResponse(result))
                }
                
            case .settingsButtonTapped, .favoriteTapped(_, _, _):
                return .none
                
            case let ._favoritesResponse(.success(response)):
                var favsImportant: [Favorite] = []
                var favorites: [Favorite] = []

                for favorite in response {
                    if favorite.isImportant {
                        favsImportant.append(favorite)
                    } else {
                        favorites.append(favorite)
                    }
                }
                
                state.favoritesImportant = favsImportant
                state.favorites = favorites
                return .none
                
            case let ._favoritesResponse(.failure(error)):
                print(error)
                return .none
            }
        }
    }
}

