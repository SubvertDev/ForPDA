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
}

extension CacheClient: DependencyKey {
    
    private static var articlesKey: String { "articlesKey" }
    private static var articlesStorage: Storage<Int, Article> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Articles", expiry: .seconds(2592000), maxSize: 163840),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: Article.self)
        )
    }
    
    private static var usersKey: String { "usersKey" }
    private static var usersStorage: Storage<Int, User> {
        return try! Storage(
            diskConfig: DiskConfig(name: "Users", expiry: .seconds(2592000), maxSize: 81920),
            memoryConfig: MemoryConfig(),
            fileManager: .default,
            transformer: TransformerFactory.forCodable(ofType: User.self)
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
                try await articlesStorage.async.removeAll()
                try await usersStorage.async.removeAll()
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
