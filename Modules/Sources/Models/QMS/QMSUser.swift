//
//  QMSUser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation

public struct QMSUser: Sendable, Codable, Hashable, Identifiable {
    public var id: Int { userId }
    
    public let userId: Int
    public let name: String
    public let flag: Int
    public let avatarUrl: URL?
    public let lastSeenOnline: Date
    public let lastMessageDate: Date
    public let unreadCount: Int
    public var chats: [QMSChatInfo]
    
    public init(
        userId: Int,
        name: String,
        flag: Int,
        avatarUrl: URL?,
        lastSeenOnline: Date,
        lastMessageDate: Date,
        unreadCount: Int,
        chats: [QMSChatInfo]
    ) {
        self.userId = userId
        self.name = name
        self.flag = flag
        self.avatarUrl = avatarUrl
        self.lastSeenOnline = lastSeenOnline
        self.lastMessageDate = lastMessageDate
        self.unreadCount = unreadCount
        self.chats = chats
    }
}
