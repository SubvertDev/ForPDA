//
//  NotificationBadgeState.swift
//  ForPDA
//

import ComposableArchitecture
import Foundation
import Models

struct NotificationBadgeState: Codable, Equatable, Sendable {

    var totalCount: Int
    var qmsUnreadCounts: [Int: Int]
    var favoriteKeys: Set<String>
    var mentionKeys: Set<String>
    var settings: NotificationsSettings2
    var userID: Int?

    static let `default` = NotificationBadgeState(
        totalCount: 0,
        qmsUnreadCounts: [:],
        favoriteKeys: [],
        mentionKeys: [],
        settings: [.qms, .qmsSystemEvents, .favorites, .mentions],
        userID: nil
    )

    init(
        totalCount: Int,
        qmsUnreadCounts: [Int: Int],
        favoriteKeys: Set<String>,
        mentionKeys: Set<String>,
        settings: NotificationsSettings2,
        userID: Int?
    ) {
        self.totalCount = totalCount
        self.qmsUnreadCounts = qmsUnreadCounts
        self.favoriteKeys = favoriteKeys
        self.mentionKeys = mentionKeys
        self.settings = settings
        self.userID = userID
    }

    init(unread: Unread, settings: NotificationsSettings2, userID: Int?) {
        self.init(
            totalCount: Self.totalCount(unread: unread, settings: settings),
            qmsUnreadCounts: [:],
            favoriteKeys: [],
            mentionKeys: [],
            settings: settings,
            userID: userID
        )

        for item in unread.items {
            guard let notification = try? item.toDomain() else { continue }
            record(notification)
        }
    }

    @discardableResult
    mutating func merge(_ notification: PDANotificationDomain) -> Int {
        switch notification {
        case let .qmsMessage(message):
            let requiredSetting: NotificationsSettings2 = message.threadID == 0 ? .qmsSystemEvents : .qms
            guard settings.contains(requiredSetting) else { return totalCount }

            let previousCount = qmsUnreadCounts[message.threadID, default: 0]
            qmsUnreadCounts[message.threadID] = message.unreadCount
            totalCount = max(0, totalCount - previousCount + message.unreadCount)

        case let .newTopic(topic):
            guard acceptsFavorite(memberID: topic.member.id, state: topic.favoriteState) else {
                return totalCount
            }
            if favoriteKeys.insert(Self.key(kind: .newTopic, primaryID: topic.forumID)).inserted {
                totalCount += 1
            }

        case let .newPost(post):
            guard acceptsFavorite(memberID: post.member.id, state: post.favoriteState) else {
                return totalCount
            }
            if favoriteKeys.insert(Self.key(kind: .newPost, primaryID: post.topicID)).inserted {
                totalCount += 1
            }

        case let .forumMention(mention):
            guard settings.contains(.mentions) else { return totalCount }
            if mentionKeys.insert(Self.key(kind: .forumMention, primaryID: mention.postID)).inserted {
                totalCount += 1
            }

        case let .siteMention(mention):
            guard settings.contains(.mentions) else { return totalCount }
            if mentionKeys.insert(Self.key(kind: .siteMention, primaryID: mention.commentID)).inserted {
                totalCount += 1
            }
        }

        return totalCount
    }

    // MARK: - Helpers

    private static func totalCount(unread: Unread, settings: NotificationsSettings2) -> Int {
        var favoritesCount = 0
        if settings.contains(.favoritesImportant) {
            favoritesCount = unread.favoritesImportantCount
        } else if settings.contains(.favorites) {
            favoritesCount = unread.favoritesCount
        }
        favoritesCount = min(unread.favoritesUnreadCount, favoritesCount)

        let mentionsCount = settings.contains(.mentions)
            ? unread.siteMentionsCount + unread.forumMentionsCount
            : 0

        var qmsCount = 0
        qmsCount += settings.contains(.qms) ? unread.qmsCount : 0
        qmsCount += settings.contains(.qmsSystemEvents) ? unread.qmsSystemCount : 0

        return favoritesCount + mentionsCount + qmsCount
    }

    private mutating func record(_ notification: PDANotificationDomain) {
        switch notification {
        case let .qmsMessage(message):
            let requiredSetting: NotificationsSettings2 = message.threadID == 0 ? .qmsSystemEvents : .qms
            guard settings.contains(requiredSetting) else { return }
            qmsUnreadCounts[message.threadID] = message.unreadCount

        case let .newTopic(topic):
            guard acceptsFavorite(memberID: topic.member.id, state: topic.favoriteState) else { return }
            favoriteKeys.insert(Self.key(kind: .newTopic, primaryID: topic.forumID))

        case let .newPost(post):
            guard acceptsFavorite(memberID: post.member.id, state: post.favoriteState) else { return }
            favoriteKeys.insert(Self.key(kind: .newPost, primaryID: post.topicID))

        case let .forumMention(mention):
            guard settings.contains(.mentions) else { return }
            mentionKeys.insert(Self.key(kind: .forumMention, primaryID: mention.postID))

        case let .siteMention(mention):
            guard settings.contains(.mentions) else { return }
            mentionKeys.insert(Self.key(kind: .siteMention, primaryID: mention.commentID))
        }
    }

    private func acceptsFavorite(
        memberID: Int,
        state: PDANotificationDomain.FavoriteState
    ) -> Bool {
        guard memberID != userID else { return false }

        switch settings.favoritesMode {
        case .all:
            break
        case .important:
            guard state.isPinned else { return false }
        case .disabled:
            return false
        }

        return state.notificationKind.kind != .doNot
    }

    private static func key(kind: PDANotification.Kind, primaryID: Int) -> String {
        "\(kind.rawValue)-\(primaryID)"
    }
}

extension SharedKey where Self == FileStorageKey<NotificationBadgeState>.Default {
    static var notificationBadgeState: Self {
        let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.subvert.forpda")!
        let url = containerURL.appending(component: "NotificationBadgeState.json")
        return Self[.fileStorage(url), default: .default]
    }
}
