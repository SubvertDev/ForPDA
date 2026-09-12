//
//  PostDraftsCache.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 12.09.2026.
//

public struct PostDraftsCache: Codable, Equatable, Sendable {
    public var topics: [Int: String]

    public mutating func clearCache() {
        topics.removeAll()
    }
}

extension PostDraftsCache {
    public static let `default` = PostDraftsCache(topics: [:])
}
