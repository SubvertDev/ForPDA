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
    public let allPosts: Bool
    
    public init(
        id: Int,
        offset: Int,
        postId: Int,
        allPosts: Bool
    ) {
        self.id = id
        self.offset = offset
        self.postId = postId
        self.allPosts = allPosts
    }
}

public extension ForumJump {
    static let mock = ForumJump(
        id: 0,
        offset: 12,
        postId: 21212,
        allPosts: false
    )
}
