import CustomDump
import Foundation
import Models
import Testing

@testable import NotificationsClient

@Suite("Notification badge state")
struct NotificationBadgeStateTests {

    @Test("QMS uses the latest unread count per thread")
    func qmsCounts() {
        var state = NotificationBadgeState.default

        expectDifference(state) {
            state.merge(qms(threadID: 10, messageID: 1, unreadCount: 1))
        } changes: {
            $0.totalCount = 1
            $0.qmsUnreadCounts[10] = 1
        }

        expectDifference(state) {
            state.merge(qms(threadID: 10, messageID: 2, unreadCount: 2))
        } changes: {
            $0.totalCount = 2
            $0.qmsUnreadCounts[10] = 2
        }

        expectDifference(state) {
            state.merge(qms(threadID: 20, messageID: 3, unreadCount: 1))
        } changes: {
            $0.totalCount = 3
            $0.qmsUnreadCounts[20] = 1
        }
    }

    @Test("A topic contributes only once")
    func postsAreUniqueByTopic() {
        var state = NotificationBadgeState.default

        expectDifference(state) {
            state.merge(post(topicID: 10, timestamp: 100))
        } changes: {
            $0.totalCount = 1
            $0.favoriteKeys.insert("3-10")
        }

        let previousState = state
        state.merge(post(topicID: 10, timestamp: 200))
        expectNoDifference(state, previousState)

        expectDifference(state) {
            state.merge(post(topicID: 20, timestamp: 300))
        } changes: {
            $0.totalCount = 2
            $0.favoriteKeys.insert("3-20")
        }
    }

    @Test("A forum contributes only once")
    func topicsAreUniqueByForum() {
        var state = NotificationBadgeState.default

        expectDifference(state) {
            state.merge(topic(forumID: 10, timestamp: 100))
        } changes: {
            $0.totalCount = 1
            $0.favoriteKeys.insert("2-10")
        }

        let previousState = state
        state.merge(topic(forumID: 10, timestamp: 200))
        expectNoDifference(state, previousState)

        expectDifference(state) {
            state.merge(topic(forumID: 20, timestamp: 300))
        } changes: {
            $0.totalCount = 2
            $0.favoriteKeys.insert("2-20")
        }
    }

    @Test("Mentions contribute once per unique item")
    func mentionsAreUnique() {
        var state = NotificationBadgeState.default

        expectDifference(state) {
            state.merge(forumMention(postID: 10))
        } changes: {
            $0.totalCount = 1
            $0.mentionKeys.insert("4-10")
        }

        let previousState = state
        state.merge(forumMention(postID: 10))
        expectNoDifference(state, previousState)

        expectDifference(state) {
            state.merge(siteMention(commentID: 10))
        } changes: {
            $0.totalCount = 2
            $0.mentionKeys.insert("5-10")
        }
    }

    @Test("Settings and user identity suppress contributions")
    func filtering() {
        var disabledState = NotificationBadgeState(
            totalCount: 0,
            qmsUnreadCounts: [:],
            favoriteKeys: [],
            mentionKeys: [],
            settings: [],
            userID: nil
        )
        let disabledBaseline = disabledState
        disabledState.merge(qms(threadID: 10, messageID: 1, unreadCount: 1))
        disabledState.merge(post(topicID: 10, timestamp: 100))
        disabledState.merge(forumMention(postID: 10))
        expectNoDifference(disabledState, disabledBaseline)

        var ownPostState = NotificationBadgeState(
            totalCount: 0,
            qmsUnreadCounts: [:],
            favoriteKeys: [],
            mentionKeys: [],
            settings: [.favorites],
            userID: 42
        )
        let ownPostBaseline = ownPostState
        ownPostState.merge(post(topicID: 10, timestamp: 100, memberID: 42))
        expectNoDifference(ownPostState, ownPostBaseline)

        var disabledFavoriteState = NotificationBadgeState.default
        let disabledFavoriteBaseline = disabledFavoriteState
        disabledFavoriteState.merge(post(topicID: 10, timestamp: 100, notificationKind: .doNot))
        expectNoDifference(disabledFavoriteState, disabledFavoriteBaseline)
    }

    @Test("Authoritative unread snapshots preserve the existing badge calculation")
    func authoritativeSnapshot() {
        let items = [
            qms(threadID: 10, messageID: 1, unreadCount: 2),
            qms(threadID: 0, messageID: 2, unreadCount: 3, memberID: 0),
            post(topicID: 10, timestamp: 100),
            post(topicID: 20, timestamp: 200),
            forumMention(postID: 30),
        ].map { $0.toRaw() }

        let unread = Unread(
            date: Date(timeIntervalSince1970: 1),
            qmsUnreadCount: 5,
            favoritesUnreadCount: 1,
            mentionsUnreadCount: 1,
            items: items
        )

        let state = NotificationBadgeState(
            unread: unread,
            settings: [.qms, .qmsSystemEvents, .favorites, .mentions],
            userID: 99
        )

        expectNoDifference(state.totalCount, 7)
        expectNoDifference(state.qmsUnreadCounts, [0: 3, 10: 2])
        expectNoDifference(state.favoriteKeys, ["3-10", "3-20"])
        expectNoDifference(state.mentionKeys, ["4-30"])
        expectNoDifference(state.userID, 99)
    }

    @Test("An empty authoritative snapshot resets badge state")
    func authoritativeReset() {
        let state = NotificationBadgeState(
            unread: .mockEmpty,
            settings: [],
            userID: nil
        )

        expectNoDifference(
            state,
            NotificationBadgeState(
                totalCount: 0,
                qmsUnreadCounts: [:],
                favoriteKeys: [],
                mentionKeys: [],
                settings: [],
                userID: nil
            )
        )
    }

    @Test("Missing persisted fields decode to safe defaults")
    func decodingMigration() throws {
        let state = try JSONDecoder().decode(
            NotificationBadgeState.self,
            from: Data("{}".utf8)
        )
        expectNoDifference(state, .default)
    }

    @Test("Malformed push payload is rejected")
    func malformedPayload() {
        expectNoDifference(PDANotification(userInfo: [:]), nil)
    }
}

@Suite("Notification cache")
struct NotificationsCacheTests {

    @Test("All notification kinds can be marked as handled")
    func markHandled() {
        var cache = NotificationsCache.default

        let identifiers = [
            identifier(kind: .qmsMessage, primaryID: 1, value: 10),
            identifier(kind: .newTopic, primaryID: 2, value: 20),
            identifier(kind: .newPost, primaryID: 3, value: 30),
            identifier(kind: .forumMention, primaryID: 4, value: 40),
            identifier(kind: .siteMention, primaryID: 5, value: 50),
        ]

        expectDifference(cache) {
            for identifier in identifiers {
                cache.markHandled(identifier)
            }
        } changes: {
            $0.qms[1] = 10
            $0.forums[2] = 20
            $0.topics[3] = 30
            $0.forumMentions[4] = 40
            $0.siteMentions[5] = 50
        }

        for identifier in identifiers {
            expectNoDifference(cache.isHandled(identifier), true)
        }

        let handledCache = cache
        for identifier in identifiers {
            cache.markHandled(identifier)
        }
        expectNoDifference(cache, handledCache)
    }

    @Test("Existing cache files decode with empty mention caches")
    func decodingMigration() throws {
        struct LegacyNotificationsCache: Encodable {
            var forums: [Int: Int]
            var topics: [Int: Int]
            var qms: [Int: Int]
        }

        let data = try JSONEncoder().encode(
            LegacyNotificationsCache(
                forums: [1: 10],
                topics: [2: 20],
                qms: [3: 30]
            )
        )

        let cache = try JSONDecoder().decode(NotificationsCache.self, from: data)

        expectNoDifference(
            cache,
            NotificationsCache(
                forums: [1: 10],
                topics: [2: 20],
                qms: [3: 30]
            )
        )
    }

    @Test("Clearing the cache includes mentions")
    func clearCache() {
        var cache = NotificationsCache(
            forums: [1: 10],
            topics: [2: 20],
            qms: [3: 30],
            forumMentions: [4: 40],
            siteMentions: [5: 50]
        )

        expectDifference(cache) {
            cache.clearCache()
        } changes: {
            $0.forums.removeAll()
            $0.topics.removeAll()
            $0.qms.removeAll()
            $0.forumMentions.removeAll()
            $0.siteMentions.removeAll()
        }
    }

    private func identifier(
        kind: PDANotification.Kind,
        primaryID: Int,
        value: Int
    ) -> PDANotification.Identifier {
        PDANotification.Identifier(kind: kind, primaryID: primaryID, value: value)
    }
}

private extension NotificationBadgeStateTests {

    func qms(
        threadID: Int,
        messageID: Int,
        unreadCount: Int,
        memberID: Int = 1
    ) -> PDANotificationDomain {
        try! PDANotification(
            kind: .qmsMessage,
            primaryID: threadID,
            primaryName: "Thread",
            memberID: memberID,
            memberName: "Member",
            value: messageID,
            extra1: unreadCount
        ).toDomain()
    }

    func topic(forumID: Int, timestamp: TimeInterval) -> PDANotificationDomain {
        try! PDANotification(
            kind: .newTopic,
            primaryID: forumID,
            primaryName: "Forum",
            memberID: 1,
            memberName: "Member",
            value: Int(timestamp),
            dateValue: 0,
            extra1: 0,
            extra2: 0
        ).toDomain()
    }

    func post(
        topicID: Int,
        timestamp: TimeInterval,
        memberID: Int = 1,
        notificationKind: PDANotificationDomain.FavoriteState.NotificationKind.Kind = .always
    ) -> PDANotificationDomain {
        let rawNotificationKind = PDANotificationDomain.FavoriteState.NotificationKind(
            kind: notificationKind,
            hasHatUpdate: false,
            isHatUpdate: false
        ).rawValue
        return try! PDANotification(
            kind: .newPost,
            primaryID: topicID,
            primaryName: "Topic",
            memberID: memberID,
            memberName: "Member",
            value: Int(timestamp),
            dateValue: 0,
            extra1: rawNotificationKind,
            extra2: 0,
            extra3: 0
        ).toDomain()
    }

    func forumMention(postID: Int) -> PDANotificationDomain {
        try! PDANotification(
            kind: .forumMention,
            primaryID: postID,
            primaryName: "Topic",
            memberID: 1,
            memberName: "Member",
            value: 100
        ).toDomain()
    }

    func siteMention(commentID: Int) -> PDANotificationDomain {
        try! PDANotification(
            kind: .siteMention,
            primaryID: commentID,
            primaryName: "Article",
            memberID: 1,
            memberName: "Member",
            value: 100
        ).toDomain()
    }
}
