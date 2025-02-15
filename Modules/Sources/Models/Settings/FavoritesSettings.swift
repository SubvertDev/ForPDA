//
//  FavoritesSettings.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.25.
//

public struct FavoritesSettings: Sendable, Codable, Hashable {
    public var isSortByName: Bool
    public var isReverseOrder: Bool
    public var isUnreadFirst: Bool
    
    public init(
        isSortByName: Bool,
        isReverseOrder: Bool,
        isUnreadFirst: Bool
    ) {
        self.isSortByName = isSortByName
        self.isReverseOrder = isReverseOrder
        self.isUnreadFirst = isUnreadFirst
    }
}

extension FavoritesSettings {
    static let `default` = FavoritesSettings(
        isSortByName: false,
        isReverseOrder: false,
        isUnreadFirst: false
    )
}
