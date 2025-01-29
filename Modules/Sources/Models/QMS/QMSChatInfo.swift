//
//  QMSChatInfo.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation

public struct QMSChatInfo: Sendable, Codable, Hashable, Identifiable {
    public let id: Int
    public let creationDate: Date
    public let lastMessageDate: Date
    public let name: String
    public let totalCount: Int
    public let unreadCount: Int
    public let lastMessageId: Int
    
    public init(
        id: Int,
        creationDate: Date,
        lastMessageDate: Date,
        name: String,
        totalCount: Int,
        unreadCount: Int,
        lastMessageId: Int
    ) {
        self.id = id
        self.creationDate = creationDate
        self.lastMessageDate = lastMessageDate
        self.name = name
        self.totalCount = totalCount
        self.unreadCount = unreadCount
        self.lastMessageId = lastMessageId
    }
}
