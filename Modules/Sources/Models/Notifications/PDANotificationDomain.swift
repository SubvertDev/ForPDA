//
//  PDANotificationDomain.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 05.08.2026.
//

import Foundation

public enum PDANotificationDomain {
    
    case qmsMessage(QMSMessage)
    case newTopic(NewTopic)
    case newPost(NewPost)
    case forumMention(ForumMention)
    case siteMention(SiteMention)

    // MARK: - Support Types
    
    public struct Member {
        public let id: Int
        public let name: String
        
        nonisolated(unsafe) public static let subvertd = Member(id: 3640948, name: "subvertd")
        nonisolated(unsafe) public static let airflare = Member(id: 6176341, name: "AirFlare")
    }

    public struct FavoriteState {
        
        public struct NotificationKind {

            public enum Kind: Int {
                case always = 0
                case once = 1
                case doNot = 2
            }

            private static let hasHatUpdateMask = 4
            private static let isHatUpdateMask = 16

            public let kind: Kind

            /// Hat-update notifications are enabled for this topic
            public let hasHatUpdate: Bool

            /// This particular notification should be treated as a hat update
            public let isHatUpdate: Bool

            public let rawValue: Int

            public init(rawValue: Int) throws {
                guard let kind = Kind(rawValue: rawValue & 0b11) else {
                    throw DecodingError.invalidRawValue(rawValue)
                }

                let hasHatUpdate = rawValue & Self.hasHatUpdateMask != 0

                self.kind = kind
                self.hasHatUpdate = hasHatUpdate
                self.isHatUpdate = hasHatUpdate && rawValue & Self.isHatUpdateMask != 0

                self.rawValue = rawValue
            }
            
            public init(kind: Kind, hasHatUpdate: Bool, isHatUpdate: Bool) {
                self.kind = kind
                self.hasHatUpdate = hasHatUpdate
                self.isHatUpdate = hasHatUpdate && isHatUpdate

                var rawValue = kind.rawValue

                if hasHatUpdate {
                    rawValue |= Self.hasHatUpdateMask
                }

                if hasHatUpdate && isHatUpdate {
                    rawValue |= Self.isHatUpdateMask
                }

                self.rawValue = rawValue
            }

            enum DecodingError: Error {
                case invalidRawValue(Int)
            }
        }
        
        public let notificationKind: NotificationKind
        public let isPinned: Bool
        
        public init(notificationKind: NotificationKind, isPinned: Bool) {
            self.notificationKind = notificationKind
            self.isPinned = isPinned
        }
        
        nonisolated(unsafe) public static let `default` = FavoriteState(
            notificationKind: NotificationKind(kind: .always, hasHatUpdate: false, isHatUpdate: false),
            isPinned: false
        )
    }
    
    // MARK: - QMS Message

    public struct QMSMessage {
        public let threadID: Int
        public let threadTitle: String
        public let member: Member
        public let messageID: Int
        public let unreadCount: Int
        
        public init(
            threadID: Int,
            threadTitle: String,
            member: Member,
            messageID: Int,
            unreadCount: Int
        ) {
            self.threadID = threadID
            self.threadTitle = threadTitle
            self.member = member
            self.messageID = messageID
            self.unreadCount = unreadCount
        }
    }

    // MARK: - New Topic
    
    public struct NewTopic {
        public let forumID: Int
        public let forumTitle: String
        public let member: Member
        public let lastPostDate: Date
        public let lastVisitDate: Date
        public let favoriteState: FavoriteState
        
        public init(
            forumID: Int,
            forumTitle: String,
            member: Member,
            lastPostDate: Date,
            lastVisitDate: Date,
            favoriteState: FavoriteState
        ) {
            self.forumID = forumID
            self.forumTitle = forumTitle
            self.member = member
            self.lastPostDate = lastPostDate
            self.lastVisitDate = lastVisitDate
            self.favoriteState = favoriteState
        }
    }
    
    // MARK: - New Post

    public struct NewPost {
        public let topicID: Int
        public let topicTitle: String
        public let member: Member
        public let lastPostDate: Date
        public let lastVisitDate: Date
        public let favoriteState: FavoriteState
        public let pinnedPostUpdateDate: Date
        
        public init(
            topicID: Int,
            topicTitle: String,
            member: Member,
            lastPostDate: Date,
            lastVisitDate: Date,
            favoriteState: FavoriteState,
            pinnedPostUpdateDate: Date
        ) {
            self.topicID = topicID
            self.topicTitle = topicTitle
            self.member = member
            self.lastPostDate = lastPostDate
            self.lastVisitDate = lastVisitDate
            self.favoriteState = favoriteState
            self.pinnedPostUpdateDate = pinnedPostUpdateDate
        }
        
        public static func make(
            topicID: Int,
            topicTitle: String,
            member: PDANotificationDomain.Member = .subvertd,
            lastPostDate: Date = .now,
            lastVisitDate: Date = .never,
            favoriteState: PDANotificationDomain.FavoriteState = .default,
            pinnedPostUpdateDate: Date = .never
        ) -> NewPost {
            NewPost(
                topicID: topicID,
                topicTitle: topicTitle,
                member: member,
                lastPostDate: lastPostDate,
                lastVisitDate: lastVisitDate,
                favoriteState: favoriteState,
                pinnedPostUpdateDate: pinnedPostUpdateDate
            )
        }
    }

    // MARK: - Forum Mention
    
    public struct ForumMention {
        public let postID: Int
        public let topicTitle: String
        public let member: Member
        public let topicID: Int
        
        public init(
            postID: Int,
            topicTitle: String,
            member: Member,
            topicID: Int
        ) {
            self.postID = postID
            self.topicTitle = topicTitle
            self.member = member
            self.topicID = topicID
        }
    }
    
    // MARK: - Site Mention

    public struct SiteMention {
        public let commentID: Int
        public let postTitle: String
        public let member: Member
        public let postID: Int
        
        public init(
            commentID: Int,
            postTitle: String,
            member: Member,
            postID: Int
        ) {
            self.commentID = commentID
            self.postTitle = postTitle
            self.member = member
            self.postID = postID
        }
    }
}

// MARK: - Extension

public extension PDANotificationDomain {
    func toRaw() -> PDANotification {
        switch self {
        case let .qmsMessage(model):
            PDANotification(
                kind: .qmsMessage,
                primaryID: model.threadID,
                primaryName: model.threadTitle,
                memberID: model.member.id,
                memberName: model.member.name,
                value: model.messageID,
                dateValue: nil,
                extra1: model.unreadCount,
                extra2: nil,
                extra3: nil
            )
        case let .newTopic(model):
            PDANotification(
                kind: .newTopic,
                primaryID: model.forumID,
                primaryName: model.forumTitle,
                memberID: model.member.id,
                memberName: model.member.name,
                value: Int(model.lastPostDate.timeIntervalSince1970),
                dateValue: Int(model.lastVisitDate.timeIntervalSince1970),
                extra1: model.favoriteState.notificationKind.rawValue,
                extra2: model.favoriteState.isPinned ? 1 : 0,
                extra3: nil
            )
        case let .newPost(model):
            PDANotification(
                kind: .newPost,
                primaryID: model.topicID,
                primaryName: model.topicTitle,
                memberID: model.member.id,
                memberName: model.member.name,
                value: Int(model.lastPostDate.timeIntervalSince1970),
                dateValue: Int(model.lastVisitDate.timeIntervalSince1970),
                extra1: model.favoriteState.notificationKind.rawValue,
                extra2: model.favoriteState.isPinned ? 1 : 0,
                extra3: Int(model.pinnedPostUpdateDate.timeIntervalSince1970)
            )
        case let .forumMention(model):
            PDANotification(
                kind: .forumMention,
                primaryID: model.postID,
                primaryName: model.topicTitle,
                memberID: model.member.id,
                memberName: model.member.name,
                value: model.topicID,
                dateValue: nil,
                extra1: nil,
                extra2: nil,
                extra3: nil
            )
        case let .siteMention(model):
            PDANotification(
                kind: .siteMention,
                primaryID: model.commentID,
                primaryName: model.postTitle,
                memberID: model.member.id,
                memberName: model.member.name,
                value: model.postID,
                dateValue: nil,
                extra1: nil,
                extra2: nil,
                extra3: nil
            )
        }
    }
}
