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
    public let items: [Item]
    
    public init(
        date: Date,
        qmsUnreadCount: Int,
        favoritesUnreadCount: Int,
        mentionsUnreadCount: Int,
        items: [Item]
    ) {
        self.date = date
        self.qmsUnreadCount = qmsUnreadCount
        self.favoritesUnreadCount = favoritesUnreadCount
        self.mentionsUnreadCount = mentionsUnreadCount
        self.items = items
    }
    
    public struct Item: Codable, Sendable, Hashable {
        public let id: Int
        public let name: String
        public let authorId: Int
        public let authorName: String
        public let timestamp: Int
        public let unreadCount: Int
        public let category: Category
        
        public enum Category: Int, Codable, Sendable {
            case qms = 1
            case forum = 2
            case topic = 3
            case forumMention = 4
            case siteMention = 5
        }
        
        public init(
            id: Int,
            name: String,
            authorId: Int,
            authorName: String,
            timestamp: Int,
            unreadCount: Int,
            category: Category
        ) {
            self.id = id
            self.name = name
            self.authorId = authorId
            self.authorName = authorName
            self.timestamp = timestamp
            self.unreadCount = unreadCount
            self.category = category
        }
    }
}

public extension Unread {
    static let mock = Unread(
        date: .now,
        qmsUnreadCount: 2,
        favoritesUnreadCount: 0,
        mentionsUnreadCount: 0,
        items: [
            Item(
                id: 12345677,
                name: "ForPDA now with Notifications",
                authorId: 1234536,
                authorName: "ForPDA",
                timestamp: 21315526,
                unreadCount: 2,
                category: Item.Category.qms
            )
        ]
    )
}
