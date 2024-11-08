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
    public let flag: Int
    public let description: String
    public let announcements: [AnnouncementInfo]
    public let subforums: [ForumInfo]
    public let topicsCount: Int
    public let topics: [TopicInfo]
    public let navigation: [ForumInfo]
    
    public init(
        id: Int,
        name: String,
        flag: Int,
        description: String,
        announcements: [AnnouncementInfo],
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
            .mockCategory,
            .mock
        ],
        topicsCount: 1709,
        topics: [
            .mock
        ],
        navigation: [
            ForumInfo(
                id: 200,
                name: "Forum heading",
                flag: 1
            )
        ]
    )
}
