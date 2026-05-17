//
//  ForumJump.swift
//  ForPDA
//
//  Created by Xialtal on 9.01.25.
//

public struct ForumJump: Codable, Hashable, Sendable {
    public let id: Int
    public let offset: Int
    public let postId: Int
    public let postsFilter: TopicPostsFilter
    
    public init(
        id: Int,
        offset: Int,
        postId: Int,
        postsFilter: TopicPostsFilter
    ) {
        self.id = id
        self.offset = offset
        self.postId = postId
        self.postsFilter = postsFilter
    }
}

public extension ForumJump {
    static let mock = ForumJump(
        id: 0,
        offset: 12,
        postId: 21212,
        postsFilter: .onlyDefault
    )
}
