//
//  FavoriteContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.25.
//

public enum FavoriteContextMenuAction: Sendable {
    case setImportant(Int, Bool)
    case copyLink(Int)
    case delete(Int)
}
