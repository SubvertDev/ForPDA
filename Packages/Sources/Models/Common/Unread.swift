//
//  Unread.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import Foundation

public struct Unread: Codable, Sendable, Hashable {
    public let date: Date
    public let unreadCount: Int
    public let items: [Item]
    
    public init(
        date: Date,
        unreadCount: Int,
        items: [Item]
    ) {
        self.date = date
        self.unreadCount = unreadCount
        self.items = items
    }
    
    public struct Item: Codable, Sendable, Hashable {
        public let id: Int
        public let name: String
        public let authorId: Int
        public let authorName: String
        public let lastMessageId: Int
        public let unreadCount: Int
        public let category: Category
        
        public enum Category: UInt8, Codable, Sendable {
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
            lastMessageId: Int,
            unreadCount: Int,
            category: Category
        ) {
            self.id = id
            self.name = name
            self.authorId = authorId
            self.authorName = authorName
            self.lastMessageId = lastMessageId
            self.unreadCount = unreadCount
            self.category = category
        }
    }
}

public extension Unread {
    static let mock = Unread(
        date: .now,
        unreadCount: 2,
        items: [
            Item(
                id: 12345677,
                name: "ForPDA now with Notifications",
                authorId: 1234536,
                authorName: "ForPDA",
                lastMessageId: 21315526,
                unreadCount: 2,
                category: Item.Category.qms
            )
        ]
    )
}
