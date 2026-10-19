//
//  NotificationsCache.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 12.08.2026.
//

public struct NotificationsCache: Codable, Equatable, Sendable {

    public var forums: [Int: Int]
    public var topics: [Int: Int]
    public var qms: [Int: Int]
    public var forumMentions: [Int: Int]
    public var siteMentions: [Int: Int]

    public init(
        forums: [Int: Int],
        topics: [Int: Int],
        qms: [Int: Int],
        forumMentions: [Int: Int] = [:],
        siteMentions: [Int: Int] = [:]
    ) {
        self.forums = forums
        self.topics = topics
        self.qms = qms
        self.forumMentions = forumMentions
        self.siteMentions = siteMentions
    }

    private enum CodingKeys: String, CodingKey {
        case forums
        case topics
        case qms
        case forumMentions
        case siteMentions
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        forums = try container.decodeIfPresent([Int: Int].self, forKey: .forums) ?? [:]
        topics = try container.decodeIfPresent([Int: Int].self, forKey: .topics) ?? [:]
        qms = try container.decodeIfPresent([Int: Int].self, forKey: .qms) ?? [:]
        forumMentions = try container.decodeIfPresent([Int: Int].self, forKey: .forumMentions) ?? [:]
        siteMentions = try container.decodeIfPresent([Int: Int].self, forKey: .siteMentions) ?? [:]
    }

    public func isHandled(_ identifier: PDANotification.Identifier) -> Bool {
        switch identifier.kind {
        case .qmsMessage:
            qms[identifier.primaryID] == identifier.value
        case .newTopic:
            forums[identifier.primaryID] == identifier.value
        case .newPost:
            topics[identifier.primaryID] == identifier.value
        case .forumMention:
            forumMentions[identifier.primaryID] == identifier.value
        case .siteMention:
            siteMentions[identifier.primaryID] == identifier.value
        }
    }

    public mutating func markHandled(_ identifier: PDANotification.Identifier) {
        switch identifier.kind {
        case .qmsMessage:
            qms[identifier.primaryID] = identifier.value
        case .newTopic:
            forums[identifier.primaryID] = identifier.value
        case .newPost:
            topics[identifier.primaryID] = identifier.value
        case .forumMention:
            forumMentions[identifier.primaryID] = identifier.value
        case .siteMention:
            siteMentions[identifier.primaryID] = identifier.value
        }
    }

    public mutating func clearCache() {
        forums.removeAll()
        topics.removeAll()
        qms.removeAll()
        forumMentions.removeAll()
        siteMentions.removeAll()
    }
}

extension NotificationsCache {
    public static let `default` = NotificationsCache(
        forums: [:],
        topics: [:],
        qms: [:],
        forumMentions: [:],
        siteMentions: [:]
    )
}
