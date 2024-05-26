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
    @Dependency(\.parsingClient) static var parsingClient
    public var newsList: @Sendable (_ page: Int) async throws -> [NewsPreview]
    public var news: @Sendable (_ url: URL) async throws -> [NewsElement]
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
            let raw = try await NewsService().news(page: page) // RELEASE: Refactor NewsService to TCA way?
            let newsList = try await parsingClient.parseNewsList(raw)
            return newsList
        },
        news: { url in
            let raw = try await NewsService().article(path: url.pathComponents)
            let news = try await parsingClient.parseNews(document: raw)
            return news
        }
    )
    
    public static let previewValue = Self(
        newsList: { page in
            try await Task.sleep(for: .seconds(2))
            return (1...10).map { _ in .mock() }
        },
        news: { url in
            try await Task.sleep(for: .seconds(2))
            return [.text(TextElement(text: "Lorem Ipsum I Guess?"))]
        }
    )
    
    public static let testValue = Self()
}

extension NewsClient {
    private struct LoadError: Error {}
    
    public static let failedToLoad = Self(
        newsList: { _ in throw LoadError() },
        news:     { _ in throw LoadError() }
    )
    
    public static let infiniteLoading = Self(
        newsList: { _ in try await Task.never() },
        news:     { _ in try await Task.never() }
    )
}
