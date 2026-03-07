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
        favorites: [.mock()],
        favoritesCount: 1
    )
    
    static let mockTwoPages = Favorite(
        favorites: (1..<35).map { _ in .mock() },
        favoritesCount: 35
    )
    
    static let mockLoading = Favorite(
        favorites: (1..<20).map { _ in .mock() },
        favoritesCount: 20
    )
    
    static let mockEmpty = Favorite(
        favorites: [],
        favoritesCount: 0
    )
}
