//
//  FavoritesRequest.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.25.
//

import Foundation
import PDAPI
import Models

public struct FavoritesRequest: Sendable {
    public let sort: [FavoriteSortType]
    public let offset: Int
    public let perPage: Int
    
    nonisolated(unsafe) public var transferSort: [MemberCommand.Favorites.Sort] {
        return sort.compactMap { type in
            switch type {
            case .byName:      return .byName
            case .reverse:     return .reverse
            case .unreadFirst: return .unreadFirst
            }
        }
    }
    
    public init(
        sort: [FavoriteSortType],
        offset: Int,
        perPage: Int
    ) {
        self.sort = sort
        self.offset = offset
        self.perPage = perPage
    }
}
