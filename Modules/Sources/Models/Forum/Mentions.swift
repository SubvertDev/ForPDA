//
//  Mentions.swift
//  Models
//
//  Created by Ilia Lubianoi on 19.02.2026.
//

import Foundation

public struct Mentions: Codable, Hashable, Sendable {
    public let mentions: [Mention]
    public let mentionsCount: Int
    
    public init(
        mentions: [Mention],
        mentionsCount: Int
    ) {
        self.mentions = mentions
        self.mentionsCount = mentionsCount
    }
}

public extension Mentions {
    static let mock = Mentions(
        mentions: [
            .mock
        ],
        mentionsCount: 1
    )
}
