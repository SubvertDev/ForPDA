//
//  TopicInfo.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct TopicInfo: Sendable, Hashable, Codable, Identifiable {
    public let id: Int
    public let name: String
    public let description: String
    public let flag: Int
    public let postsCount: Int
    public let lastPost: LastPost
        
    public init(id: Int, name: String, description: String, flag: Int, postsCount: Int, lastPost: LastPost) {
        self.id = id
        self.name = name
        self.description = description
        self.flag = flag
        self.postsCount = postsCount
        self.lastPost = lastPost
    }
        
    public struct LastPost: Sendable, Hashable, Codable {
        public let date: Date
        public let userId: Int
        public let username: String
            
        public init(date: Date, userId: Int, username: String) {
            self.date = date
            self.userId = userId
            self.username = username
        }
    }
}

public extension TopicInfo {
    static let mock = TopicInfo(
        id: 21,
        name: "Example of pinned topic.",
        description: "", // without description
        flag: 97, // pinned
        postsCount: 1, // means, that only topic cap exists
        lastPost: TopicInfo.LastPost(
            date: Date(timeIntervalSince1970: 1768475013),
            userId: 6176341,
            username: "AirFlare"
        )
    )
}

