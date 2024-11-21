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

public struct CacheClient: Sendable {
    // Utility
    public var configure: @Sendable () -> Void
    public var removeAll: @Sendable () async throws -> Void
    // Articles
    public var preloadImages: @Sendable ([URL]) async -> Void
    public var cacheArticle: @Sendable (Article) async throws -> Void
    public var getArticle: @Sendable (_ id: Int) async -> Article?
    // Users
    public var cacheUser: @Sendable (User) async throws -> Void
    public var getUser: @Sendable (_ id: Int) async -> User?
    // Favorites
    public var cacheFavorites: @Sendable ([FavoriteInfo]) async throws -> Void
    public var getFavorites: @Sendable () async -> [FavoriteInfo]?
    // Forums List
    public var cacheForumsList: @Sendable ([ForumInfo]) async throws -> Void
    public var getForumsList: @Sendable () async -> [ForumInfo]
    // Topics
    public var cacheParsedPostContent: @Sendable (_ id: Int, _ content: NSAttributedString) throws -> Void
    public var getParsedPostContent: @Sendable (_ id: Int) -> NSAttributedString?
    // Background Tasks
    public var setLastBackgroundTaskInvokeTime: @Sendable (TimeInterval) async throws -> Void
    public var getLastBackgroundTaskInvokeTime: @Sendable () async -> TimeInterval?
    // Notifications
    public var setLastMessageOfUnreadItem: @Sendable (_ messageId: Int, _ dialogId: Int) throws -> Void
    public var getLastMessageOfUnreadItem: @Sendable (_ messageId: Int) -> Int?
}

extension CacheClient: DependencyKey {
    
    private static var articlesStorage: Storage<Int, Article> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Articles", expiry: .seconds(2592000), maxSize: 163840),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Article.self)
        )
    }
    
    private static var usersStorage: Storage<Int, User> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Users", expiry: .seconds(2592000), maxSize: 81920),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: User.self)
        )
    }
    
    private static var favoritesKey: String { "favoritesKey" }
    private static var favoritesStorage: Storage<String, [FavoriteInfo]> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Favorites", expiry: .seconds(2592000), maxSize: 81920),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: [FavoriteInfo].self)
        )
    }
    
    private static var forumsListKey: String { "forumsListKey" }
    private static var forumsListStorage: Storage<String, [ForumInfo]> {
        return try! Storage(
            diskConfig: DiskConfig(name: "ForumsList", expiry: .seconds(2592000), maxSize: 81920),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: [ForumInfo].self)
        )
    }
    
    private static var parsedPostsContentStorage: Storage<Int, AttributedString> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Posts Contents", expiry: .seconds(2592000), maxSize: 163840),
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
            diskConfig: DiskConfig(name: "Articles", expiry: .seconds(2592000), maxSize: 163840),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Int.self)
        )
    }
    
    // TODO: Handle try/catch?
    public static var liveValue: CacheClient {
        CacheClient(
            configure: {
                ImagePipeline.shared = ImagePipeline(configuration: .withDataCache(sizeLimit: 1024 * 1024 * 100))
            },
            removeAll: {
                ImagePipeline.shared.cache.removeAll()
                try articlesStorage.removeAll()
                try usersStorage.removeAll()
                try favoritesStorage.removeAll()
                try forumsListStorage.removeAll()
                try parsedPostsContentStorage.removeAll()
                try lastBackgroundTaskInvokeTimeStorage.removeAll()
                try notificationsStorage.removeAll()
            },
            preloadImages: { urls in
                urls.forEach { ImagePipeline.shared.loadImage(with: $0, completion: { _ in }) }
            },
            cacheArticle: { article in
                try articlesStorage.setObject(article, forKey: article.id)
            },
            getArticle: { articleId in
                return try? articlesStorage.object(forKey: articleId)
            },
            cacheUser: { user in
                try usersStorage.setObject(user, forKey: user.id)
            },
            getUser: { userId in
                return try? usersStorage.object(forKey: userId)
            },
            cacheFavorites: { favorites in
                try favoritesStorage.setObject(favorites, forKey: favoritesKey)
            },
            getFavorites: {
                return try? favoritesStorage.object(forKey: favoritesKey)
            },
            cacheForumsList: { forumsList in
                try forumsListStorage.setObject(forumsList, forKey: forumsListKey)
            },
            getForumsList: {
                return (try? forumsListStorage.object(forKey: forumsListKey)) ?? []
            },
            cacheParsedPostContent: { id, content in
                let codable = AttributedString(content)
                try! parsedPostsContentStorage.setObject(codable, forKey: id)
            },
            getParsedPostContent: { id in
                if let codable = try? parsedPostsContentStorage.object(forKey: id) {
                    return NSAttributedString(codable)
                } else {
                    return nil
                }
            },
            setLastBackgroundTaskInvokeTime: { date in
                try lastBackgroundTaskInvokeTimeStorage.setObject(date, forKey: lastBackgroundTaskInvokeTimeKey)
            },
            getLastBackgroundTaskInvokeTime: {
                return try? lastBackgroundTaskInvokeTimeStorage.object(forKey: lastBackgroundTaskInvokeTimeKey)
            },
            setLastMessageOfUnreadItem: { messageId, dialogId in
                try notificationsStorage.setObject(messageId, forKey: dialogId)
            },
            getLastMessageOfUnreadItem: { dialogId in
                return try? notificationsStorage.object(forKey: dialogId)
            }
        )
    }
}

extension DependencyValues {
    public var cacheClient: CacheClient {
        get { self[CacheClient.self] }
        set { self[CacheClient.self] = newValue }
    }
}
