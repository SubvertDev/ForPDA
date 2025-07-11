//
//  ReputationVote.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.25.
//

import Foundation

public struct ReputationVote: Codable, Hashable, Sendable {
    public let id: Int
    public let flag: Int
    public let toId: Int
    public let toName: String
    public let authorId: Int
    public let authorName: String
    public let reason: String
    public let modified: VoteModified?
    public let createdIn: VoteCreatedIn
    public let createdAt: Date
    public let isDown: Bool
    
    public init(
        id: Int,
        flag: Int,
        toId: Int,
        toName: String,
        authorId: Int,
        authorName: String,
        reason: String,
        modified: VoteModified?,
        createdIn: VoteCreatedIn,
        createdAt: Date,
        isDown: Bool
    ) {
        self.id = id
        self.flag = flag
        self.toId = toId
        self.toName = toName
        self.authorId = authorId
        self.authorName = authorName
        self.reason = reason
        self.modified = modified
        self.createdIn = createdIn
        self.createdAt = createdAt
        self.isDown = isDown
    }
    
    public enum VoteCreatedIn: Codable, Hashable, Sendable {
        case profile
        case topic(id: Int, topicName: String, postId: Int)
        case site(id: Int, articleName: String, commentId: Int)
    }
    
    public struct VoteModified: Codable, Hashable, Sendable {
        public let userId: Int
        public let userName: String
        public let isDenied: Bool
        
        public init(userId: Int, userName: String, isDenied: Bool) {
            self.userId = userId
            self.userName = userName
            self.isDenied = isDenied
        }
    }
}

public extension ReputationVote {
    static let mock = ReputationVote(
        id: 1,
        flag: 1,
        toId: 23232,
        toName: "AirFlare",
        authorId: 6176341,
        authorName: "4spader",
        reason: "For fun",
        modified: nil,
        createdIn: .profile,
        createdAt: .now,
        isDown: false
    )
}
