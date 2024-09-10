//
//  Topic.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Topic: Sendable, Codable {
    public let id: Int
    public let name: String
    public let description: String
    public let flag: Int
    public let createdAt: Date
    public let authorId: Int
    public let authorName: String
    public let curatorId: Int
    public let curatorName: String
    public let poll: Optional<Poll>
    public let postsCount: Int
    public let posts: [Post]
    public let navigation: [ForumInfo]
    
    public struct Poll: Sendable, Codable {
        public let name: String // 0
        public let voted: Bool // 2
        public let totalVotes: Int // 1
        public let options: [Option] // 3
        
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
            public let name: String // 0
            public let several: Bool // 1
            public let choices: [Choice] // 2 - value; 3 - key
            
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
        poll: Optional<Poll>,
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
        poll: .some(Poll(
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
        )),
        postsCount: 1709,
        posts: [
            .mock
        ],
        navigation: [
            ForumInfo(id: 1, name: "iOS - Apps", flag: 32)
        ]
    )
}
