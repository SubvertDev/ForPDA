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
    public var connect: @Sendable () async throws -> Void
    public var getArticlesList: @Sendable (_ offset: Int, _ amount: Int) async throws -> [ArticlePreview]
}

extension APIClient: DependencyKey {
    
    private static let api = try! PDAPI()
    
    public static var liveValue: APIClient {
        APIClient(
            connect: {
                try api.connect(as: .anonymous)
            },
            getArticlesList: { offset, amount in
                let rawString = try api.get(.articlesList(offset: offset, amount: amount))
                let parsedResponse = try await parsingClient.parseArticlesList(rawString: rawString)
                return parsedResponse
            }
        )
    }
    
    public static var previewValue: APIClient {
        APIClient(
            connect: {
                
            }, 
            getArticlesList: { _, _ in
                return Array(repeating: .mock, count: 30)
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
