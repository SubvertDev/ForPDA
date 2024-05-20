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
            try await Task.sleep(for: .seconds(2))
            return (1...10).map { _ in .mock() }
        },
        news: { _ in
            try await Task.sleep(for: .seconds(2))
            return []
        }
    )
    
    public static let testValue = Self()
}

extension NewsClient {
    private struct LoadError: Error {}
    
    public static let failedToLoad = Self(
        newsList: { _ in
            throw LoadError()
        },
        news: { _ in
            throw LoadError()
        }
    )
    
    public static let infiniteLoading = Self(
        newsList: { _ in
            try await Task.sleep(for: .seconds(86400))
            throw LoadError()
        },
        news: { _ in
            try await Task.sleep(for: .seconds(86400))
            throw LoadError()
        }
    )
}
