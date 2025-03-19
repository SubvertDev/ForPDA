//
//  CacheClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.08.2024.
//

import Foundation
import ComposableArchitecture
import Cache
import Nuke
import Models
import AnalyticsClient

// MARK: - Client

public struct CacheClient: Sendable {
    // Common
    public var configure: @Sendable () -> Void
    public var removeAll: @Sendable () async throws -> Void
    
    // Articles
    public var preloadImages: @Sendable ([URL]) async -> Void
    public var setArticle: @Sendable (Article) async -> Void
    public var getArticle: @Sendable (_ id: Int) async -> Article?
    
    // Users
    public var setUser: @Sendable (User) async -> Void
    public var getUser: @Sendable (_ id: Int) async -> User?
    
    // Favorites
    public var setFavorites: @Sendable (Favorite) async -> Void
    public var getFavorites: @Sendable () async -> Favorite?
    
    // Forums List
    public var setForumsList: @Sendable ([ForumInfo]) async -> Void
    public var getForumsList: @Sendable () async -> [ForumInfo]?
    
    // Forums
    public var setForum: @Sendable (_ id: Int, _ forums: Forum) async -> Void
    public var getForum: @Sendable (_ id: Int) async -> Forum?
    
    // Post Content
    public var cacheParsedPostContent: @Sendable (_ id: Int, _ content: [TopicTypeUI]) async -> Void
    public var getParsedPostContent: @Sendable (_ id: Int) async -> [TopicTypeUI]?
    public var removeAllParsedPostContent: @Sendable () async -> Void
    
    // Background Tasks
    public var setLastBackgroundTaskInvokeTime: @Sendable (TimeInterval) async -> Void
    public var getLastBackgroundTaskInvokeTime: @Sendable () async -> [TimeInterval]
    
    // Notifications
    public var setLastTimestampOfUnreadItem: @Sendable (_ timestamp: Int, _ itemId: Int) async -> Void
    public var getLastTimestampOfUnreadItem: @Sendable (_ timestamp: Int) async -> Int?
    public var setTopicIdOfUnreadItem: @Sendable (_ topicId: Int) async -> Void
    public var deleteTopicIdOfUnreadItem: @Sendable (_ topicId: Int) async -> Void
    public var getTopicIdOfUnreadItem: @Sendable (_ topicId: Int) async -> Int?
}

// MARK: - Dependency Key

extension CacheClient: DependencyKey {
    
    // MARK: - Live Value
    
    public static var liveValue: CacheClient {
        @Dependency(\.analyticsClient) var analytics
        
        return CacheClient(
            
            // MARK: - Common
            
            configure: {
                ImagePipeline.shared = ImagePipeline(configuration: .withDataCache(sizeLimit: 1024 * 1024 * 100))
            },
            removeAll: {
                ImagePipeline.shared.cache.removeAll()
                try await articlesStorage.async.removeAll()
                try await usersStorage.async.removeAll()
                try await favoritesStorage.async.removeAll()
                try await forumsListStorage.async.removeAll()
                try await forumsStorage.async.removeAll()
                try await parsedPostsContentStorage.async.removeAll()
                try await lastBackgroundTaskInvokeTimeStorage.async.removeAll()
                try await notificationsStorage.async.removeAll()
            },
            
            // MARK: - Articles
            
            preloadImages: { urls in
                urls.forEach { ImagePipeline.shared.loadImage(with: $0, completion: { _ in }) }
            },
            setArticle: { article in
                try? await articlesStorage.async.setObject(article, forKey: article.id)
            },
            getArticle: { articleId in
                return try? await articlesStorage.async.object(forKey: articleId)
            },
            
            // MARK: - User
            
            setUser: { user in
                try? await usersStorage.async.setObject(user, forKey: user.id)
            },
            getUser: { userId in
                return try? await usersStorage.async.object(forKey: userId)
            },
            
            // MARK: - Favorites
            
            setFavorites: { favorites in
                try? await favoritesStorage.async.setObject(favorites, forKey: favoritesKey)
            },
            getFavorites: {
                return try? await favoritesStorage.async.object(forKey: favoritesKey)
            },
            
            // MARK: - Forums List
            
            setForumsList: { forumsList in
                try? forumsListStorage.setObject(forumsList, forKey: forumsListKey)
            },
            getForumsList: {
                return try? await forumsListStorage.async.object(forKey: forumsListKey)
            },
            
            // MARK: - Forums
            
            setForum: { id, forum in
                try? forumsStorage.setObject(forum, forKey: id)
            },
            getForum: { id in
                return try? await forumsStorage.async.object(forKey: id)
            },
            
            // MARK: - Post Content
            
            cacheParsedPostContent: { id, content in
                try? await parsedPostsContentStorage.async.setObject(content, forKey: id)
            },
            getParsedPostContent: { id in
                return try? await parsedPostsContentStorage.async.object(forKey: id)
            },
            removeAllParsedPostContent: {
                try? await parsedPostsContentStorage.async.removeAll()
            },
            
            // MARK: - Background Tasks
            
            setLastBackgroundTaskInvokeTime: { date in
                var invokes = (try? await lastBackgroundTaskInvokeTimeStorage.async.object(forKey: lastBackgroundTaskInvokeTimeKey)) ?? []
                invokes.append(date)
                try? await lastBackgroundTaskInvokeTimeStorage.async.setObject(invokes, forKey: lastBackgroundTaskInvokeTimeKey)
            },
            getLastBackgroundTaskInvokeTime: {
                return (try? await lastBackgroundTaskInvokeTimeStorage.async.object(forKey: lastBackgroundTaskInvokeTimeKey)) ?? []
            },
            
            // MARK: - Notifications
            
            setLastTimestampOfUnreadItem: { timestamp, itemId in
                try? await notificationsStorage.async.setObject(timestamp, forKey: itemId)
            },
            getLastTimestampOfUnreadItem: { itemId in
                return try? await notificationsStorage.async.object(forKey: itemId)
            },
            setTopicIdOfUnreadItem: { topicId in
                try? await notificationsStorage.async.setObject(topicId, forKey: topicId)
            },
            deleteTopicIdOfUnreadItem: { topicId in
                try? await notificationsStorage.async.removeObject(forKey: topicId)
            },
            getTopicIdOfUnreadItem: { topicId in
                return try? await notificationsStorage.async.object(forKey: topicId)
            }
        )
    }
}

// MARK: - Storages

private extension CacheClient {
    
    private static var articlesStorage: Storage<Int, Article> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Articles", expiry: .date(.days(7)), maxSize: .megabytes(2)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Article.self)
        )
    }
    
    private static var usersStorage: Storage<Int, User> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Users", expiry: .date(.days(30)), maxSize: .kilobytes(100)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: User.self)
        )
    }
    
    private static var favoritesKey: String { "favoritesKey" }
    private static var favoritesStorage: Storage<String, Favorite> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Favorites", expiry: .date(.days(30)), maxSize: .kilobytes(100)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Favorite.self)
        )
    }
    
    private static var forumsListKey: String { "forumsListKey" }
    private static var forumsListStorage: Storage<String, [ForumInfo]> {
        return try! Storage(
            diskConfig: DiskConfig(name: "ForumsList", expiry: .date(.days(30)), maxSize: .megabytes(1)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: [ForumInfo].self)
        )
    }
    
    private static var forumsStorage: Storage<Int, Forum> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Forums", expiry: .date(.days(30)), maxSize: .megabytes(1)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Forum.self)
        )
    }
    
    private static var parsedPostsContentStorage: Storage<Int, [TopicTypeUI]> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Posts Contents", expiry: .date(.days(30))),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: [TopicTypeUI].self)
        )
    }
    
    private static var lastBackgroundTaskInvokeTimeKey: String { "lastBackgroundTaskInvokeTimeKey" }
    private static var lastBackgroundTaskInvokeTimeStorage: Storage<String, [TimeInterval]> {
        return try! Storage(
            diskConfig: DiskConfig(name: "LastBackgroundTaskInvokeTime", expiry: .date(.days(30))),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: [TimeInterval].self)
        )
    }
    
    private static var notificationsStorage: Storage<Int, Int> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Notifications", expiry: .date(.days(30)), maxSize: .kilobytes(100)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Int.self)
        )
    }
}

// MARK: - Extensions

extension DependencyValues {
    public var cacheClient: CacheClient {
        get { self[CacheClient.self] }
        set { self[CacheClient.self] = newValue }
    }
}

extension Date {
    static func days(_ days: TimeInterval) -> Date {
        return Date().addingTimeInterval(days * 24 * 60 * 60)
    }
}

extension UInt {
    static func kilobytes(_ bytes: UInt) -> UInt {
        return bytes * 1024
    }
    static func megabytes(_ megabytes: UInt) -> UInt {
        return megabytes * 1024 * 1024
    }
}
