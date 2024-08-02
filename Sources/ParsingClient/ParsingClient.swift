//
//  ParsingClient.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//
//  swiftlint:disable force_try cyclomatic_complexity function_body_length type_body_length file_length

import Foundation
import ComposableArchitecture
import Models

// MARK: - New Implementation

@DependencyClient
public struct ParsingClient: Sendable {
    public var parseArticlesList: @Sendable (_ rawString: String) async throws -> [ArticlePreview]
    public var parseArticle: @Sendable (_ rawString: String) async throws -> Article
    public var parseArticleElements: @Sendable (_ article: Article) async throws -> [ArticleElement]
    public var parseCaptchaUrl: @Sendable (_ rawString: String) async throws -> URL
    public var parseLoginResponse: @Sendable (_ rawString: String) async throws -> AuthResponse
}

extension DependencyValues {
    public var parsingClient: ParsingClient {
        get { self[ParsingClient.self] }
        set { self[ParsingClient.self] = newValue }
    }
}

extension ParsingClient: DependencyKey {
    public static let liveValue = Self(
        parseArticlesList: { rawString in
            return try ArticlesListParser.parse(from: rawString)
        },
        parseArticle: { rawString in
            return try ArticleParser.parse(from: rawString)
        },
        parseArticleElements: { article in
            return try ArticleElementParser.parse(from: article)
        },
        parseCaptchaUrl: { rawString in
            return try AuthParser.parseCaptchaUrl(rawString: rawString)
        },
        parseLoginResponse: { rawString in
            return try AuthParser.parseLoginResponse(rawString: rawString)
        }
    )
}
