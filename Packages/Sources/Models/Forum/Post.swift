//
//  Post.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Post: Sendable, Hashable, Decodable {
    public let id: Int
    public let first: Bool
    public let flag: Int
    public let content: String
    public let author: Author
    public let karma: Int
    public let attachments: [Attachment]
    public let createdAt: Date
    public let lastEdit: LastEdit?
    
    // TODO: 12 => 0 on first post; other - 1; can be 17 also
    
    public init(
        id: Int,
        first: Bool,
        flag: Int,
        content: String,
        author: Author,
        karma: Int,
        attachments: [Attachment],
        createdAt: Date,
        lastEdit: LastEdit?
    ) {
        self.id = id
        self.first = first
        self.flag = flag
        self.content = content
        self.author = author
        self.karma = karma
        self.attachments = attachments
        self.createdAt = createdAt
        self.lastEdit = lastEdit
    }
    
    public struct Attachment: Sendable, Hashable, Decodable {
        public let id: Int
        public let type: AttachmentType
        public let name: String
        public let size: Int
        public let metadata: Metadata?
        
        public enum AttachmentType: Sendable, Hashable, Decodable {
            case file
            case image
        }
        
        public struct Metadata: Sendable, Hashable, Decodable {
            public let url: String
            public let width: Int
            public let height: Int
            
            public init(width: Int, height: Int, url: String) {
                self.url = url
                self.width = width
                self.height = height
            }
        }
        
        public init(
            id: Int,
            type: AttachmentType,
            name: String,
            size: Int,
            metadata: Metadata?
        ) {
            self.id = id
            self.type = type
            self.name = name
            self.size = size
            self.metadata = metadata
        }
    }
    
    public struct LastEdit: Sendable, Hashable, Decodable {
        public let userId: Int
        public let username: String
        public let reason: String
        public let date: Date
        
        public init(userId: Int, username: String, reason: String, date: Date) {
            self.userId = userId
            self.username = username
            self.reason = reason
            self.date = date
        }
    }
    
    public struct Author: Sendable, Hashable, Decodable {
        public let id: Int
        public let name: String
        public let avatarUrl: String
        public let lastSeenDate: Date
        public let signature: String
        public let reputationCount: Int
        
        public init(
            id: Int,
            name: String,
            avatarUrl: String,
            lastSeenDate: Date,
            signature: String,
            reputationCount: Int
        ) {
            self.id = id
            self.name = name
            self.avatarUrl = avatarUrl
            self.lastSeenDate = lastSeenDate
            self.signature = signature
            self.reputationCount = reputationCount
        }
    }
}

extension Post {
    static let mock = Post(
        id: 12,
        first: false,
        flag: 8,
        content: "Lorem ipsum...",
        author: Author(
            id: 6176341,
            name: "AirFlare",
            avatarUrl: "https://4pda.to/s/qirtgbz15jFlUN6eSvTuZz0ONRHsD2iINxx7kHnM6ZC7MBrlcF.png",
            lastSeenDate: Date(timeIntervalSince1970: 1725706883),
            signature: "",
            reputationCount: 312
        ),
        karma: 0,
        attachments: [
            Attachment(
                id: 14308454,
                type: Attachment.AttachmentType.image,
                name: "IMG_2369.png",
                size: 62246,
                metadata: Attachment.Metadata(
                    width: 281,
                    height: 500,
                    url: "https://cs2c9f.4pda.ws/14308454.png"
                )
            )
        ],
        createdAt: Date(timeIntervalSince1970: 1725706321),
        lastEdit: LastEdit(
            userId: 6176341,
            username: "AirFlare",
            reason: "for fun",
            date: Date(timeIntervalSince1970: 1725706883)
        )
    )
}
