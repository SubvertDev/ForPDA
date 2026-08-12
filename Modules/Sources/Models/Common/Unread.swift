//
//  Unread.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import Foundation

public struct Unread: Codable, Sendable, Hashable {
    public let date: Date
    public let qmsUnreadCount: Int
    public let favoritesUnreadCount: Int
    public let mentionsUnreadCount: Int
    public let items: [PDANotification]
    
    public var forumCount: Int {
        return items.filter { $0.kind == .newTopic }.count
    }
    
    public var topicCount: Int {
        return items.filter { $0.kind == .newPost }.count
    }
    
    public var siteMentionsCount: Int {
        return items.filter { $0.kind == .siteMention }.count
    }
    
    public var forumMentionsCount: Int {
        return items.filter { $0.kind == .forumMention }.count
    }
    
    public init(
        date: Date,
        qmsUnreadCount: Int,
        favoritesUnreadCount: Int,
        mentionsUnreadCount: Int,
        items: [PDANotification]
    ) {
        self.date = date
        self.qmsUnreadCount = qmsUnreadCount
        self.favoritesUnreadCount = favoritesUnreadCount
        self.mentionsUnreadCount = mentionsUnreadCount
        self.items = items
    }
}

public extension Unread {
    static let mock = Unread(
        date: .now,
        qmsUnreadCount: 2,
        favoritesUnreadCount: 0,
        mentionsUnreadCount: 0,
        items: [
            PDANotificationDomain
                .qmsMessage(
                    .init(
                        threadID: 123456789,
                        threadTitle: "ForPDA now with Notifications",
                        member: .airflare,
                        messageID: 123,
                        unreadCount: 2
                    )
                )
        ]
            .map { $0.toRaw() }
    )
    
    static let mockEmpty = Unread(
        date: .now,
        qmsUnreadCount: 0,
        favoritesUnreadCount: 0,
        mentionsUnreadCount: 0,
        items: []
    )
    
    static let mockBadges = Unread(
        date: .now,
        qmsUnreadCount: 15,
        favoritesUnreadCount: 20,
        mentionsUnreadCount: 3,
        items: []
    )
}
