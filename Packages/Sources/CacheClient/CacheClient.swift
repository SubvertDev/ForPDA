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
    public var cacheArticle: @Sendable (Article) async -> Void
    public var getArticle: @Sendable (_ id: Int) async -> Article?
    
    // Users
    public var cacheUser: @Sendable (User) async -> Void
    public var getUser: @Sendable (_ id: Int) async -> User?
    
    // Favorites
    public var cacheFavorites: @Sendable ([FavoriteInfo]) async -> Void
    public var getFavorites: @Sendable () async -> [FavoriteInfo]?
    
    // Forums List
    public var cacheForumsList: @Sendable ([ForumInfo]) async -> Void
    public var getForumsList: @Sendable () async -> [ForumInfo]
    
    // Post Content
    public var cacheParsedPostContent: @Sendable (_ id: Int, _ content: NSAttributedString) async -> Void
    public var getParsedPostContent: @Sendable (_ id: Int) async -> NSAttributedString?
    
    // Background Tasks
    public var setLastBackgroundTaskInvokeTime: @Sendable (TimeInterval) async -> Void
    public var getLastBackgroundTaskInvokeTime: @Sendable () async -> TimeInterval?
    
    // Notifications
    public var setLastMessageOfUnreadItem: @Sendable (_ messageId: Int, _ dialogId: Int) async -> Void
    public var getLastMessageOfUnreadItem: @Sendable (_ messageId: Int) async -> Int?
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
                try await parsedPostsContentStorage.async.removeAll()
                try await lastBackgroundTaskInvokeTimeStorage.async.removeAll()
                try await notificationsStorage.async.removeAll()
            },
            
            // MARK: - Articles
            
            preloadImages: { urls in
                urls.forEach { ImagePipeline.shared.loadImage(with: $0, completion: { _ in }) }
            },
            cacheArticle: { article in
                do {
                    try await articlesStorage.async.setObject(article, forKey: article.id)
                } catch {
                    analytics.capture(error)
                }
            },
            getArticle: { articleId in
                do {
                    return try await articlesStorage.async.object(forKey: articleId)
                } catch {
                    analytics.capture(error)
                    return nil
                }
            },
            
            // MARK: - User
            
            cacheUser: { user in
                do {
                    try await usersStorage.async.setObject(user, forKey: user.id)
                } catch {
                    analytics.capture(error)
                }
            },
            getUser: { userId in
                do {
                    return try await usersStorage.async.object(forKey: userId)
                } catch {
                    analytics.capture(error)
                    return nil
                }
            },
            
            // MARK: - Favorites
            
            cacheFavorites: { favorites in
                do {
                    try await favoritesStorage.async.setObject(favorites, forKey: favoritesKey)
                } catch {
                    analytics.capture(error)
                }
            },
            getFavorites: {
                do {
                    return try await favoritesStorage.async.object(forKey: favoritesKey)
                } catch {
                    analytics.capture(error)
                    return nil
                }
            },
            
            // MARK: - Forums List
            
            cacheForumsList: { forumsList in
                do {
                    try forumsListStorage.setObject(forumsList, forKey: forumsListKey)
                } catch {
                    analytics.capture(error)
                }
            },
            getForumsList: {
                do {
                    return try await forumsListStorage.async.object(forKey: forumsListKey)
                } catch {
                    analytics.capture(error)
                    return []
                }
            },
            
            // MARK: - Post Content
            
            cacheParsedPostContent: { id, content in
                return
                
                do {
                    try await parsedPostsContentStorage.async.setObject(AttributedString(content), forKey: id)
                } catch {
                    analytics.capture(error)
                }
            },
            getParsedPostContent: { id in
                return nil
                
                do {
                    let attributedString = try await parsedPostsContentStorage.async.object(forKey: id)
                    return NSAttributedString(attributedString)
                } catch {
                    analytics.capture(error)
                    return nil
                }
            },
            
            // MARK: - Background Tasks
            
            setLastBackgroundTaskInvokeTime: { date in
                do {
                    try await lastBackgroundTaskInvokeTimeStorage.async.setObject(date, forKey: lastBackgroundTaskInvokeTimeKey)
                } catch {
                    analytics.capture(error)
                }
            },
            getLastBackgroundTaskInvokeTime: {
                do {
                    return try await lastBackgroundTaskInvokeTimeStorage.async.object(forKey: lastBackgroundTaskInvokeTimeKey)
                } catch {
                    analytics.capture(error)
                    return nil
                }
            },
            
            // MARK: - Notifications
            
            setLastMessageOfUnreadItem: { messageId, dialogId in
                do {
                    try await notificationsStorage.async.setObject(messageId, forKey: dialogId)
                } catch {
                    analytics.capture(error)
                }
            },
            getLastMessageOfUnreadItem: { dialogId in
                do {
                    return try await notificationsStorage.async.object(forKey: dialogId)
                } catch {
                    analytics.capture(error)
                    return nil
                }
            }
        )
    }
}

// MARK: - Storages

private extension CacheClient {
    
    private static var articlesStorage: Storage<Int, Article> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Articles", expiry: .date(.days(7)), maxSize: .megabytes(16)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Article.self)
        )
    }
    
    private static var usersStorage: Storage<Int, User> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Users", expiry: .date(.days(30)), maxSize: .megabytes(16)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: User.self)
        )
    }
    
    private static var favoritesKey: String { "favoritesKey" }
    private static var favoritesStorage: Storage<String, [FavoriteInfo]> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Favorites", expiry: .date(.days(30)), maxSize: .megabytes(16)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: [FavoriteInfo].self)
        )
    }
    
    private static var forumsListKey: String { "forumsListKey" }
    private static var forumsListStorage: Storage<String, [ForumInfo]> {
        return try! Storage(
            diskConfig: DiskConfig(name: "ForumsList", expiry: .date(.days(30)), maxSize: .megabytes(16)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: [ForumInfo].self)
        )
    }
    
    private static var parsedPostsContentStorage: Storage<Int, AttributedString> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Posts Contents", expiry: .date(.days(30)), maxSize: .megabytes(16)),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: AttributedString.self)
        )
    }
    
    private static var lastBackgroundTaskInvokeTimeKey: String { "lastBackgroundTaskInvokeTimeKey" }
    private static var lastBackgroundTaskInvokeTimeStorage: Storage<String, TimeInterval> {
        return try! Storage(
            diskConfig: DiskConfig(name: "LastBackgroundTaskInvokeTime", expiry: .never),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: TimeInterval.self)
        )
    }
    
    private static var notificationsStorage: Storage<Int, Int> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Notifications", expiry: .date(.days(30)), maxSize: .megabytes(16)),
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
    static func megabytes(_ megabytes: UInt) -> UInt {
        return megabytes * 1024 * 1024
    }
}
