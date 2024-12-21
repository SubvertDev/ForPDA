//
//  SetFavoriteRequest.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.12.2024.
//

import Foundation
import PDAPI

public struct SetFavoriteRequest: Sendable {
    public let id: Int
    public let action: ActionType
    public let type: RequestType
    
    nonisolated(unsafe) public var transferType: MemberCommand.Favorites.Element {
        switch type {
        case .forum: return .forum
        case .topic: return .topic
        }
    }
    
    public init(
        id: Int,
        action: ActionType,
        type: RequestType
    ) {
        self.id = id
        self.action = action
        self.type = type
    }
    
    public enum ActionType: Sendable {
        case add
        case delete
    }
    
    public enum RequestType: Sendable {
        case forum
        case topic
    }
}
