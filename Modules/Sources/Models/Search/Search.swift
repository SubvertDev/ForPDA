//
//  Search.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import Foundation

public struct SearchResponse: Sendable, Hashable, Decodable {
    public let metadata: [Int]
    public let publications: [Publication]
    
    public init(metadata: [Int], publications: [Publication]) {
        self.metadata = metadata
        self.publications = publications
    }
}

public struct Publication: Sendable, Hashable, Decodable {
    public let unknownValue1: Int
    public let unknownValue2: Int
    public let unknownValue3: Int
    public let postName: String
    public let messageId: Int
    public let unknownValue4: Int
    public let unknownValue5: Int
    public let unknownValue6: Int
    public let authorName: String
    public let unknownValue7: Int
    public let authorReputation: Int
    public let date: Date
    public let text: String
    public let authorAvatar: String
    public let signatureAuthor: String
    public let unknownValue10: Int
    
    public init(
        unknownValue1: Int,
        unknownValue2: Int,
        unknownValue3: Int,
        postName: String,
        messageId: Int,
        unknownValue4: Int,
        unknownValue5: Int,
        authorName: String,
        unknownValue6: Int,
        unknownValue7: Int,
        authorReputation: Int,
        date: Date,
        text: String,
        authorAvatar: String,
        signatureAuthor: String,
        unknownValue10: Int
    ) {
        self.unknownValue1 = unknownValue1
        self.unknownValue2 = unknownValue2
        self.unknownValue3 = unknownValue3
        self.postName = postName
        self.messageId = messageId
        self.unknownValue4 = unknownValue4
        self.unknownValue5 = unknownValue5
        self.authorName = authorName
        self.unknownValue6 = unknownValue6
        self.unknownValue7 = unknownValue7
        self.authorReputation = authorReputation
        self.date = date
        self.text = text
        self.authorAvatar = authorAvatar
        self.signatureAuthor = signatureAuthor
        self.unknownValue10 = unknownValue10
    }
}
