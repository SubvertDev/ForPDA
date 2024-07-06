//
//  APIClient.swift
//
//
//  Created by Ilia Lubianoi on 30.06.2024.
//

import Foundation
import PDAPI
import Models
import ParsingClient
import ComposableArchitecture

@DependencyClient
public struct APIClient: Sendable {
    @Dependency(\.parsingClient) static var parsingClient
    public var setLogResponses: @Sendable (_ type: ResponsesLogType) async -> Void
    public var connect: @Sendable () async throws -> Void
    public var getArticlesList: @Sendable (_ offset: Int, _ amount: Int) async throws -> [ArticlePreview]
    public var getArticle: @Sendable (_ id: Int) async throws -> Article
}

extension APIClient: DependencyKey {
    
    private static let api = try! PDAPI()
    
    public static var liveValue: APIClient {
        APIClient(
            setLogResponses: { type in
                api.setLogResponses(to: type)
            },
            connect: {
                try api.connect(as: .anonymous)
            },
            getArticlesList: { offset, amount in
                let rawString = try api.get(SiteCommand.articlesList(offset: offset, amount: amount))
                let parsedResponse = try await parsingClient.parseArticlesList(rawString: rawString)
                return parsedResponse
            },
            getArticle: { id in
                let rawString = try api.get(SiteCommand.article(id: id))
                let parsedResponse = try await parsingClient.parseArticle(rawString: rawString)
                return parsedResponse
            }
        )
    }
    
    public static var previewValue: APIClient {
        APIClient(
            setLogResponses: { _ in
                
            },
            connect: {
                
            }, 
            getArticlesList: { _, _ in
                return Array(repeating: .mock, count: 30)
            },
            getArticle: { _ in
                return .mock
            }
        )
    }
}

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
