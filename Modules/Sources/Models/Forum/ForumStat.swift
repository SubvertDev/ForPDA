//
//  ForumStat.swift
//  ForPDA
//
//  Created by Xialtal on 14.06.25.
//

public struct ForumStat: Sendable, Equatable {
    public let id: Int
    public let name: String
    public let description: String
    public let flag: Int
    public let globalAnnouncement: String // TODO: Think about good naming & rename in TopicInfo/Topic (I forgot xD)
    public let subforumsCount: Int
    public let topicsCount: Int
    public let postsCount: Int
    public let moderators: [ForumModerator]
    
    public struct ForumModerator: Sendable, Equatable, Identifiable {
        public let id: Int
        public let name: String
        public let group: User.Group
        
        public init(id: Int, name: String, group: User.Group) {
            self.id = id
            self.name = name
            self.group = group
        }
    }
    
    public init(
        id: Int,
        name: String,
        description: String,
        flag: Int,
        globalAnnouncement: String,
        subforumsCount: Int,
        topicsCount: Int,
        postsCount: Int,
        moderators: [ForumModerator]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.flag = flag
        self.globalAnnouncement = globalAnnouncement
        self.subforumsCount = subforumsCount
        self.topicsCount = topicsCount
        self.postsCount = postsCount
        self.moderators = moderators
    }
}

public extension ForumStat {
    static let mock = ForumStat(
        id: 5,
        name: "4PDA - Administrative",
        description: "Simple description.",
        flag: 100,
        globalAnnouncement: "This is global announcement title.",
        subforumsCount: 3,
        topicsCount: 1456,
        postsCount: 81734,
        moderators: [
            .init(id: 0, name: "Admins", group: .admin),
            .init(id: 1, name: "AirFlare", group: .regular)
        ]
    )
}
