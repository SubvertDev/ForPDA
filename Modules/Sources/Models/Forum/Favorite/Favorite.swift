//
//  Favorite.swift
//  ForPDA
//
//  Created by Xialtal on 12.11.24.
//

public struct Favorite: Codable, Hashable, Sendable {
    public let favorites: [FavoriteInfo]
    public let favoritesCount: Int
    
    public init(
        favorites: [FavoriteInfo],
        favoritesCount: Int
    ) {
        self.favorites = favorites
        self.favoritesCount = favoritesCount
    }
}

public extension Favorite {
    static let mock = Favorite(
        favorites: [.mock],
        favoritesCount: 1
    )
}
