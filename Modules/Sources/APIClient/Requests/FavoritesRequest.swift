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
    public let offset: Int
    public let perPage: Int
    public let isSortByName: Bool
    public let isSortReverse: Bool
    public let isUnreadFirst: Bool
    
    nonisolated public var transferSort: [MemberCommand.Favorites.Sort] {
        return [
            isSortByName  ? .byName : nil,
            isSortReverse ? .reverse : nil,
            isUnreadFirst ? .unreadFirst : nil,
        ]
        .compactMap { $0 }
    }
    
    public init(
        offset: Int,
        perPage: Int,
        isSortByName: Bool,
        isSortReverse: Bool,
        isUnreadFirst: Bool
    ) {
        self.offset = offset
        self.perPage = perPage
        self.isUnreadFirst = isUnreadFirst
        self.isSortByName = isSortByName
        self.isSortReverse = isSortReverse
    }
}
