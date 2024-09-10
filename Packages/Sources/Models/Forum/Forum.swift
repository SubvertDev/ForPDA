//
//  Forum.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Forum: Sendable, Hashable, Codable {
    public let id: Int
    public let name: String
    public let flag: Int // 64
    public let description: String
    public let announcements: [Announcement]
    public let subforums: [ForumInfo]
    public let topicsCount: Int // 42
    public let topics: [TopicInfo]
    public let navigation: [ForumInfo]
    
    public init(
        id: Int,
        name: String,
        flag: Int,
        description: String,
        announcements: [Announcement],
        subforums: [ForumInfo],
        topicsCount: Int,
        topics: [TopicInfo],
        navigation: [ForumInfo]
    ) {
        self.id = id
        self.name = name
        self.flag = flag
        self.description = description
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
        flag: 64,
        description: "Wow, this is forum description...",
        announcements: [
            .mock
        ],
        subforums: [
            ForumInfo(
                id: 21,
                name: "First subforum",
                flag: 5,
                redirectUrl: "https://url..."
            ),
            ForumInfo(
                id: 543,
                name: "Second subforum",
                flag: 64,
                redirectUrl: .none
            )
        ],
        topicsCount: 1709,
        topics: [
            .mock
        ],
        navigation: [
            ForumInfo(
                id: 200,
                name: "Forum heading",
                flag: 1,
                redirectUrl: .none
            )
        ]
    )
}
