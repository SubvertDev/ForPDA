//
//  TopicInfo.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation
import SwiftUI

public struct TopicInfo: Sendable, Hashable, Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String
    public let flag: Int
    public let postsCount: Int
    public let lastPost: LastPost
    
    public var isUnread: Bool {
        return (flag & 32) != 0
    }
    
    public var isClosed: Bool {
        return (flag & 4) != 0
    }
    
    public var isPinned: Bool {
        return (flag & 1) != 0
    }
    
    public var isFavorite: Bool {
        return (flag & 8) != 0
    }
        
    public init(id: Int, name: String, description: String, flag: Int, postsCount: Int, lastPost: LastPost) {
        self.id = id
        self.name = name
        self.description = description
        self.flag = flag
        self.postsCount = postsCount
        self.lastPost = lastPost
    }
        
    public struct LastPost: Sendable, Hashable, Codable {
        public let date: Date
        public let userId: Int
        public let username: String
        
        public var formattedDate: LocalizedStringKey {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            
            if Calendar.current.isDateInToday(date) {
                return LocalizedStringKey("Today, \(formatter.string(from: date))")
            } else if Calendar.current.isDateInYesterday(date) {
                return LocalizedStringKey("Yesterday, \(formatter.string(from: date))")
            } else {
                formatter.dateFormat = "dd.MM.yy, HH:mm"
                return LocalizedStringKey(formatter.string(from: date))
            }
        }
        
        public init(date: Date, userId: Int, username: String) {
            self.date = date
            self.userId = userId
            self.username = username
        }
    }
}

public extension TopicInfo {
    static let mockPinned = TopicInfo(
        id: 21,
        name: "Example of pinned topic",
        description: "",
        flag: 37,
        postsCount: 1,
        lastPost: TopicInfo.LastPost(
            date: Date(timeIntervalSince1970: 1768475013),
            userId: 6176341,
            username: "AirFlare"
        )
    )
    
    static let mockLong = TopicInfo(
        id: Int.random(in: 1..<1000000),
        name: "Topic example. Topic example. Topic example. Topic example. Topic example. Topic example.",
        description: "",
        flag: 64,
        postsCount: 10,
        lastPost: TopicInfo.LastPost(
            date: .now,
            userId: 6176341,
            username: "AirFlare"
        )
    )
    
    static let mockToday = TopicInfo(
        id: Int.random(in: 1..<1000000),
        name: "Topic example",
        description: "",
        flag: 64,
        postsCount: 10,
        lastPost: TopicInfo.LastPost(
            date: .now,
            userId: 6176341,
            username: "AirFlare"
        )
    )
    
    static let mockTodayUnread = TopicInfo(
        id: Int.random(in: 1..<1000000),
        name: "Topic example",
        description: "",
        flag: 96,
        postsCount: 10,
        lastPost: TopicInfo.LastPost(
            date: .now,
            userId: 6176341,
            username: "AirFlare"
        )
    )
    
    static let mockYesterday = TopicInfo(
        id: Int.random(in: 1..<1000000),
        name: "Topic example",
        description: "",
        flag: 64,
        postsCount: 10,
        lastPost: TopicInfo.LastPost(
            date: .now.addingTimeInterval(-86400),
            userId: 6176341,
            username: "AirFlare"
        )
    )
    
    static let mockWeekAgo = TopicInfo(
        id: Int.random(in: 1..<1000000),
        name: "Topic example",
        description: "",
        flag: 64,
        postsCount: 10,
        lastPost: TopicInfo.LastPost(
            date: .now.addingTimeInterval(-86400 * 7),
            userId: 6176341,
            username: "AirFlare"
        )
    )
}
