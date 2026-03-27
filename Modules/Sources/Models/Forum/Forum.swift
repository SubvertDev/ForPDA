//
//  Forum.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Forum: Codable, Sendable, Hashable {
    public let id: Int
    public let name: String
    public let flag: ForumFlag
    public let globalAnnouncement: String
    public let announcements: [AnnouncementInfo]
    public let subforums: [ForumInfo]
    public let topicsCount: Int
    public var topics: [TopicInfo]
    public let navigation: [ForumInfo]
    
    public var canCreateTopic: Bool {
        return flag.contains(.canPost)
    }
    
    public var isFavorite: Bool {
        return flag.contains(.favorite)
    }
    
    public init(
        id: Int,
        name: String,
        flag: ForumFlag,
        globalAnnouncement: String,
        announcements: [AnnouncementInfo],
        subforums: [ForumInfo],
        topicsCount: Int,
        topics: [TopicInfo],
        navigation: [ForumInfo]
    ) {
        self.id = id
        self.name = name
        self.flag = flag
        self.globalAnnouncement = globalAnnouncement
        self.announcements = announcements
        self.subforums = subforums
        self.topicsCount = topicsCount
        self.topics = topics
        self.navigation = navigation
    }
}

public extension Forum {
    static let mock = Forum(
        id: 1,
        name: "Test Forum",
        flag: .canPost,
        globalAnnouncement: "Wow, [b]this is[/b] SPARTA (global announcement)...",
        announcements: [
            .mock
        ],
        subforums: [
            .mockCategory,
            .mock
        ],
        topicsCount: 35,
        topics: [
            [.mockPinned],
            [.mockLong],
            [.mockToday],
            [.mockYesterday],
            Array(repeating: .mockWeekAgo, count: 26)
        ].flatMap { $0
        },
        navigation: [
            .mockCategory
        ]
    )
}
