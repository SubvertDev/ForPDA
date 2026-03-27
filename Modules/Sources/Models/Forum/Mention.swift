//
//  Mention.swift
//  Models
//
//  Created by Ilia Lubianoi on 19.02.2026.
//

import Foundation

public struct Mention: Hashable, Codable, Sendable {
    
    public enum ContentType: Int, Codable, Sendable {
        case article = 1
        case topic = 0
    }
    
    public let type: ContentType
    public let isSeen: Bool
    public let sourceId: Int
    public let sourceName: String
    public let targetId: Int // ArticleID or PostID
    public let userId: Int
    public let username: String
    public let userGroup: User.Group
    public let lastSeenDate: Date
    public let reputationCount: Int
    public let mentionDate: Date
    public let userAvatarUrl: URL?
    
    public init(
        type: ContentType,
        isSeen: Bool,
        sourceId: Int,
        sourceName: String,
        targetId: Int,
        userId: Int,
        username: String,
        userGroup: User.Group,
        lastSeenDate: Date,
        reputationCount: Int,
        mentionDate: Date,
        userAvatarUrl: URL?
    ) {
        self.type = type
        self.isSeen = isSeen
        self.sourceId = sourceId
        self.sourceName = sourceName
        self.targetId = targetId
        self.userId = userId
        self.username = username
        self.userGroup = userGroup
        self.lastSeenDate = lastSeenDate
        self.reputationCount = reputationCount
        self.mentionDate = mentionDate
        self.userAvatarUrl = userAvatarUrl
    }
}

public extension Mention {
    static let mock = Mention(
        type: .topic,
        isSeen: false,
        sourceId: 0,
        sourceName: "Mock Topic",
        targetId: 0,
        userId: 0,
        username: "subvertd",
        userGroup: .beginning,
        lastSeenDate: .now,
        reputationCount: 0,
        mentionDate: .now,
        userAvatarUrl: URL(string: "/")
    )
}
