//
//  User.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation

public struct User: Sendable, Hashable, Codable {
    public let id: Int
    public let nickname: String
    public let imageUrl: URL
    public let registrationDate: Date
    public let lastSeenDate: Date
    public let userCity: String
    public let karma: Int
    public let posts: Int
    public let comments: Int
    public let reputation: Int
    public let topics: Int
    public let replies: Int
    public let email: String
    
    public init(
        id: Int,
        nickname: String,
        imageUrl: URL?,
        registrationDate: Date,
        lastSeenDate: Date,
        userCity: String,
        karma: Int,
        posts: Int,
        comments: Int,
        reputation: Int,
        topics: Int,
        replies: Int,
        email: String
    ) {
        self.id = id
        self.nickname = nickname
        self.imageUrl = imageUrl ?? Links.defaultAvatar
        self.registrationDate = registrationDate
        self.lastSeenDate = lastSeenDate
        self.userCity = userCity
        self.karma = karma
        self.posts = posts
        self.comments = comments
        self.reputation = reputation
        self.topics = topics
        self.replies = replies
        self.email = email
    }
}

public extension User {
    static let mock = User(
        id: 0,
        nickname: "Test Nickname",
        imageUrl: Links.defaultAvatar,
        registrationDate: Date(timeIntervalSince1970: 1168875045),
        lastSeenDate: Date(timeIntervalSince1970: 1168875045),
        userCity: "Moscow",
        karma: 1500,
        posts: 23,
        comments: 173,
        reputation: 78,
        topics: 5,
        replies: 82,
        email: "some@email.com"
    )
}
