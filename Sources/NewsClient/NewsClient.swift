//
//  NewsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation
import ComposableArchitecture
import Models
import ParsingClient

@DependencyClient
public struct NewsClient: Sendable {
    public var newsList: @Sendable (_ page: Int) async throws -> [NewsPreview]
    public var news: @Sendable (_ url: URL) async throws -> [Any]
}

extension DependencyValues {
    public var newsClient: NewsClient {
        get { self[NewsClient.self] }
        set { self[NewsClient.self] = newValue }
    }
}

extension NewsClient: DependencyKey {
    
    public static var liveValue = Self(
        newsList: { page in
            let pageRaw = try await NewsService().news(page: page) // RELEASE: Translate NewsService to TCA way?
            @Dependency(\.parsingClient) var parsingClient
            let newsList = try await parsingClient.parseNewsList(pageRaw)
            return newsList
        },
        news: { url in
            return []
        }
    )
    
    public static let previewValue = Self(
        newsList: { page in
            try await Task.sleep(for: .seconds(1))
            return Array(repeating: .mock, count: 64)
        },
        news: { _ in
            try await Task.sleep(for: .seconds(1))
            return []
        }
    )
    
    public static let testValue = Self()
}

extension NewsClient {
    public static let failedToLoad = Self(
        newsList: { _ in
            struct LoadError: Error {}
            throw LoadError()
        },
        news: { _ in
            struct LoadError: Error {}
            throw LoadError()
        }
    )
}

//@DependencyClient
//public struct NewsClient: Sendable {
//    public var newsList: @Sendable (_ page: Int) async throws -> [NewsPreview]
//    public var news: @Sendable (_ url: URL) async throws -> [any NewsElement] // RELEASE: Remove "Models."
//}
//
//extension DependencyValues {
//    public var newsClient: NewsClient {
//        get { self[NewsClient.self] }
//        set { self[NewsClient.self] = newValue }
//    }
//}
//
//extension NewsClient: DependencyKey {
//    public static let liveValue = Self(
//        newsList: { page in
//            let pageRaw = try await NewsService().news(page: page) // RELEASE: Translate NewsService to TCA way?
//            @Dependency(\.parsingClient) var parsingClient
//            let newsList = try await parsingClient.parseNewsList(pageRaw)
//            return newsList
//        },
//        news: { url in
////            let pageRaw = try await NewsService().article(path: [String])
//            return [] // .mock
//        }
//    )
//    
//    public static let previewValue = Self(
//        newsList: { page in
//            try await Task.sleep(for: .seconds(1))
//            return Array(repeating: .mock, count: 64)
//        },
//        news: { _ in
//            try await Task.sleep(for: .seconds(1))
//            return [] // .mock
//        }
//    )
//    
//    public static let testValue = Self()
//}
//
//extension NewsClient {
//    public static let failedToLoad = Self(
//        newsList: { _ in
//            struct LoadError: Error {}
//            throw LoadError()
//        },
//        news: { _ in
//            struct LoadError: Error {}
//            throw LoadError()
//        }
//    )
//}
