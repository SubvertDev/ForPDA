//
//  Topic.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Topic: Sendable, Decodable {
    public let id: Int
    public let name: String
    public let description: String
    public let flag: Int
    public let createdAt: Date
    public let authorId: Int
    public let authorName: String
    public let curatorId: Int
    public let curatorName: String
    public let poll: Poll?
    public let postsCount: Int
    public let posts: [Post]
    public let navigation: [ForumInfo]
    
    public struct Poll: Sendable, Decodable {
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
        
        public struct Choice: Sendable, Codable {
            public let id: Int
            public let votes: Int
            public let name: String
            
            public init(id: Int, name: String, votes: Int) {
                self.id = id
                self.votes = votes
                self.name = name
            }
        }
        
        public struct Option: Sendable, Codable {
            public let name: String
            public let several: Bool
            public let choices: [Choice]
            
            public init(name: String, several: Bool, choices: [Choice]) {
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
        flag: Int,
        createdAt: Date,
        authorId: Int,
        authorName: String,
        curatorId: Int,
        curatorName: String,
        poll: Poll?,
        postsCount: Int,
        posts: [Post],
        navigation: [ForumInfo]
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
    }
}

public extension Topic {
    static let mock = Topic(
        id: 3242552,
        name: "ForPDA",
        description: "Unofficial 4PDA client for iOS.",
        flag: 8,
        createdAt: Date(timeIntervalSince1970: 1725706883),
        authorId: 3640948,
        authorName: "4spander",
        curatorId: 6176341,
        curatorName: "AirFlare",
        poll: Poll(
            name: "Some simple poll...",
            voted: false,
            totalVotes: 2134,
            options: [
                Poll.Option(
                    name: "Select this choise...",
                    several: false,
                    choices: [
                        Poll.Choice(id: 2, name: "First choice", votes: 2)
                    ]
                )
            ]
        ),
        postsCount: 1709,
        posts: [
            .mock
        ],
        navigation: [
            ForumInfo(id: 1, name: "iOS - Apps", flag: 32)
        ]
    )
}
