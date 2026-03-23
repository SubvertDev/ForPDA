//
//  Topic.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Topic: Codable, Sendable, Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let description: String
    public let flag: ForumFlag
    public let createdAt: Date
    public let authorId: Int
    public let authorName: String
    public let curatorId: Int
    public let curatorName: String
    public let poll: Poll?
    public let postsCount: Int
    public let posts: [Post]
    public let navigation: [ForumInfo]
    public let postTemplateName: String?
    
    public var canPost: Bool {
        return flag.contains(.canPost) && !flag.contains(.marker)
    }
    
    public var canModerate: Bool {
        return flag.contains(.canModerate)
    }
    
    public var isFavorite: Bool
    
    public struct Poll: Sendable, Codable, Hashable {
        public let name: String
        public let voted: Bool
        public let totalVotes: Int
        public let options: [Option]
        
        public init(name: String, voted: Bool, totalVotes: Int, options: [Option]) {
            self.name = name
            self.voted = voted
            self.totalVotes = totalVotes
            self.options = options
        }
        
        public struct Choice: Sendable, Codable, Hashable, Identifiable {
            public let id: Int
            public let votes: Int
            public let name: String
            
            public init(id: Int, name: String, votes: Int) {
                self.id = id
                self.votes = votes
                self.name = name
            }
        }
        
        public struct Option: Sendable, Codable, Hashable, Identifiable {
            public let id: Int
            public let name: String
            public let several: Bool
            public let choices: [Choice]
            
            public init(id: Int, name: String, several: Bool, choices: [Choice]) {
                self.id = id
                self.name = name
                self.several = several
                self.choices = choices
            }
        }
    }
    
    public init(
        id: Int,
        name: String,
        description: String,
        flag: ForumFlag,
        createdAt: Date,
        authorId: Int,
        authorName: String,
        curatorId: Int,
        curatorName: String,
        poll: Poll?,
        postsCount: Int,
        posts: [Post],
        navigation: [ForumInfo],
        postTemplateName: String?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.flag = flag
        self.createdAt = createdAt
        self.authorId = authorId
        self.authorName = authorName
        self.curatorId = curatorId
        self.curatorName = curatorName
        self.poll = poll
        self.postsCount = postsCount
        self.posts = posts
        self.navigation = navigation
        self.postTemplateName = postTemplateName
        
        self.isFavorite = flag.contains(.favorite)
    }
}

public extension Topic {
    static let mock = Topic(
        id: 3242552,
        name: "ForPDA",
        description: "Unofficial 4PDA client for iOS.",
        flag: .canPost,
        createdAt: Date(timeIntervalSince1970: 1725706883),
        authorId: 3640948,
        authorName: "4spander",
        curatorId: 6176341,
        curatorName: "AirFlare",
        poll: .mock,
        postsCount: 5005,
        posts: [
            .mock(id: 0), .mock(id: 1), .mock(id: 2)
        ],
        navigation: [
            .mock, .mockCategory
        ],
        postTemplateName: "New update"
    )
}

public extension Topic.Poll {
    static let mock = Topic.Poll(
        name: "Some simple poll...",
        voted: false,
        totalVotes: 12,
        options: [
            .init(
                id: 0,
                name: "Select not several...",
                several: false,
                choices: [
                    .init(id: 2, name: "First choice", votes: 2),
                    .init(id: 3, name: "Second choice", votes: 4)
                ]
            ),
            .init(
                id: 1,
                name: "Select several...",
                several: true,
                choices: [
                    .init(id: 4, name: "First choice", votes: 4),
                    .init(id: 5, name: "Second choice", votes: 2)
                ]
            ),
        ]
    )
}
