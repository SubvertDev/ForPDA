//
//  ArticlePoll.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.09.2024.
//

import Foundation

public struct ArticlePoll: Sendable, Hashable, Codable {
    
    public struct Option: Sendable, Hashable, Codable {
        public let id: Int
        public let text: String
        public let votes: Int
        
        public init(
            id: Int,
            text: String,
            votes: Int
        ) {
            self.id = id
            self.text = text
            self.votes = votes
        }
    }
    
    public let id: Int
    public let title: String
    private let flag: Int
    public let totalVotes: Int
    public let options: [Option]
    
    public var singleChoice: Bool {
        return flag & 1 != 0
    }
    
    public var isVoted: Bool {
        return flag & 4 != 0
    }
    
    public init(
        id: Int,
        title: String,
        flag: Int,
        totalVotes: Int,
        options: [Option]
    ) {
        self.id = id
        self.title = title
        self.flag = flag
        self.totalVotes = totalVotes
        self.options = options
    }
}
