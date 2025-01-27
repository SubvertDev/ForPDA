//
//  NotifyFavoriteRequest.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.25.
//

import Foundation
import PDAPI
import Models

public struct NotifyFavoriteRequest: Sendable {
    public let id: Int
    public let flag: Int
    public let type: FavoriteNotifyType

    nonisolated(unsafe) public var transferType: MemberCommand.Favorites.Notify {
        switch type {
        case .always: return .always
        case .once: return .once
        case .doNot: return .doNot
        case .hatUpdate: return .hatUpdate
        }
    }
    
    public init(
        id: Int,
        flag: Int,
        type: FavoriteNotifyType
    ) {
        self.id = id
        self.flag = flag
        self.type = type
    }
}
