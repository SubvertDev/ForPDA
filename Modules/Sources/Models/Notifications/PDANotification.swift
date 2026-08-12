//
//  PDANotification.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 05.08.2026.
//

import Foundation

public struct PDANotification: Codable, Hashable, Sendable {

    public enum Kind: Int, Codable, Hashable, Sendable {
        case qmsMessage = 1
        case newTopic = 2
        case newPost = 3
        case forumMention = 4
        case siteMention = 5
    }

    var kind: Kind

    public var primaryID: Int
    var primaryName: String
    var memberID: Int
    var memberName: String
    var value: Int
    var dateValue: Int?
    var extra1: Int?
    var extra2: Int?
    var extra3: Int?
    
    public init(
        kind: Kind,
        primaryID: Int,
        primaryName: String,
        memberID: Int,
        memberName: String,
        value: Int,
        dateValue: Int? = nil,
        extra1: Int? = nil,
        extra2: Int? = nil,
        extra3: Int? = nil
    ) {
        self.kind = kind
        self.primaryID = primaryID
        self.primaryName = primaryName
        self.memberID = memberID
        self.memberName = memberName
        self.value = value
        self.dateValue = dateValue
        self.extra1 = extra1
        self.extra2 = extra2
        self.extra3 = extra3
    }
}

// MARK: - Domain Mapping

extension PDANotification {

    enum MappingError: Error {
        case missingValue(field: String, kind: Kind)
    }

    public func toDomain() throws -> PDANotificationDomain {
        switch kind {
        case .qmsMessage:
            return .qmsMessage(
                .init(
                    threadID: primaryID,
                    threadTitle: primaryName,
                    member: member,
                    messageID: value,
                    unreadCount: try require(extra1, field: "extra1")
                )
            )

        case .newTopic:
            return .newTopic(
                .init(
                    forumID: primaryID,
                    forumTitle: primaryName,
                    member: member,
                    lastPostDate: value.date,
                    lastVisitDate: try require(dateValue, field: "dateValue").date,
                    favoriteState: try favoriteState()
                )
            )

        case .newPost:
            return .newPost(
                .init(
                    topicID: primaryID,
                    topicTitle: primaryName,
                    member: member,
                    lastPostDate: value.date,
                    lastVisitDate: try require(dateValue, field: "dateValue").date,
                    favoriteState: try favoriteState(),
                    pinnedPostUpdateDate: try require(extra3, field: "extra3").date
                )
            )

        case .forumMention:
            return .forumMention(
                .init(
                    postID: primaryID,
                    topicTitle: primaryName,
                    member: member,
                    topicID: value
                )
            )

        case .siteMention:
            return .siteMention(
                .init(
                    commentID: primaryID,
                    postTitle: primaryName,
                    member: member,
                    postID: value
                )
            )
        }
    }

    private var member: PDANotificationDomain.Member {
        .init(id: memberID, name: memberName)
    }

    private func favoriteState() throws -> PDANotificationDomain.FavoriteState {
        let value = try require(extra1, field: "extra1")
        let kind = try PDANotificationDomain.FavoriteState.NotificationKind(rawValue: value)
        return PDANotificationDomain.FavoriteState(
            notificationKind: kind,
            isPinned: (try require(extra2, field: "extra2")) == 1
        )
    }

    private func require<Value>(_ value: Value?, field: String) throws -> Value {
        guard let value else {
            throw MappingError.missingValue(field: field, kind: kind)
        }

        return value
    }
}

// MARK: - Identifier

extension PDANotification {
    
    public var identifier: Identifier {
        Identifier(kind: kind, primaryID: primaryID, value: value)
    }
    
    public struct Identifier: Sendable {
        public let kind: Kind
        public let primaryID: Int
        public let value: Int
        
        public var rawValue: String { "\(kind.rawValue)-\(primaryID)-\(value)" }
        
        public init(kind: Kind, primaryID: Int, value: Int) {
            self.kind = kind
            self.primaryID = primaryID
            self.value = value
        }
        
        public init?(rawValue: String) {
            let components = rawValue.split(separator: "-")
            guard components.count == 3,
                  let rawKind = Int(components[0]),
                  let kind = Kind(rawValue: rawKind),
                  let primaryID = Int(components[1]),
                  let value = Int(components[2]) else {
                return nil
            }
            self.init(kind: kind, primaryID: primaryID, value: value)
        }
        
        public init?(userInfo: [AnyHashable: Any]) {
            guard let rawKind = PDANotification.integer(forKey: "t", in: userInfo),
                  let kind = Kind(rawValue: rawKind),
                  let primaryID = PDANotification.integer(forKey: "i", in: userInfo),
                  let value = PDANotification.integer(forKey: "v", in: userInfo) else {
                return nil
            }

            self.init(kind: kind, primaryID: primaryID, value: value)
        }
    }
    
    /// Initializer for push notification
    public init?(userInfo: [AnyHashable: Any]) {
        guard let rawKind = PDANotification.integer(forKey: "t", in: userInfo),
              let kind = Kind(rawValue: rawKind),
              let primaryID = PDANotification.integer(forKey: "i", in: userInfo),
              let primaryName = PDANotification.string(forKey: "n", in: userInfo),
              let memberID = PDANotification.integer(forKey: "ai", in: userInfo),
              let memberName = PDANotification.string(forKey: "an", in: userInfo),
              let value = PDANotification.integer(forKey: "v", in: userInfo) else {
            return nil
        }
        
        self.init(
            kind: kind,
            primaryID: primaryID,
            primaryName: primaryName,
            memberID: memberID,
            memberName: memberName,
            value: value,
            dateValue: PDANotification.integer(forKey: "vd", in: userInfo),
            extra1: PDANotification.integer(forKey: "e1", in: userInfo),
            extra2: PDANotification.integer(forKey: "e2", in: userInfo),
            extra3: PDANotification.integer(forKey: "e3", in: userInfo)
        )
    }
    
    // Helpers
    
    private static func integer(forKey key: String, in userInfo: [AnyHashable: Any]) -> Int? {
        switch userInfo[key] {
        case let value as Int:
            return value
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }
    
    private static func string(forKey key: String, in userInfo: [AnyHashable: Any]) -> String? {
        switch userInfo[key] {
        case let value as NSString:
            return String(value)
        case let value as String:
            return value
        default:
            return nil
        }
    }
}

// MARK: - Extensions

private extension Int {
    var date: Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }
}
