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

public extension QMSUser {
    static let mock = QMSUser(
        userId: 3640948,
        name: "subvertd",
        flag: 0,
        avatarUrl: URL(string: "https://4pda.to/s/mQ607BUjRwtJPp6EchK6OieRFbeetg0cLkoz12ABdz0UIO0yJd.jpg"),
        lastSeenOnline: .now,
        lastMessageDate: .now,
        unreadCount: 3,
        chats: [.mock1, .mock2]
    )
    
    static let mockEmpty = QMSUser(
        userId: 6176341,
        name: "AirFlare",
        flag: 0,
        avatarUrl: nil,
        lastSeenOnline: .now,
        lastMessageDate: Date(timeIntervalSince1970: 0),
        unreadCount: 0,
        chats: []
    )
}
