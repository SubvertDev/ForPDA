//
//  NotificationsCache.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 12.08.2026.
//

public struct NotificationsCache: Codable, Sendable {
    public var forums: [Int: Int]
    public var topics: [Int: Int]
    public var qms: [Int: Int]
    
    public mutating func clearCache() {
        forums.removeAll()
        topics.removeAll()
        qms.removeAll()
    }
}

extension NotificationsCache {
    public static let `default` = NotificationsCache(
        forums: [:],
        topics: [:],
        qms: [:]
    )
}
