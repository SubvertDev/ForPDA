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
    public var setLogResponses: @Sendable (_ type: ResponsesLogType) async -> Void
    public var connect: @Sendable () async throws -> Void
    public var getArticlesList: @Sendable (_ offset: Int, _ amount: Int) async throws -> [ArticlePreview]
    public var getArticle: @Sendable (_ id: Int) async throws -> Article
    public var getCaptcha: @Sendable () async throws -> URL
    public var authorize: @Sendable (_ login: String, _ password: String, _ hidden: Bool, _ captcha: Int) async throws -> AuthResponse
}

extension APIClient: DependencyKey {
    
    private nonisolated(unsafe) static let api = try! PDAPI()
    
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
                @Dependency(\.parsingClient) var parsingClient
                let parsedResponse = try await parsingClient.parseArticlesList(rawString: rawString)
                return parsedResponse
            },
            getArticle: { id in
                let rawString = try api.get(SiteCommand.article(id: id))
                @Dependency(\.parsingClient) var parsingClient
                let parsedResponse = try await parsingClient.parseArticle(rawString: rawString)
                return parsedResponse
            },
            getCaptcha: {
                let request = LoginRequest(name: "", password: "", hidden: false)
                let rawString = try api.get(AuthCommand.login(data: request))
                @Dependency(\.parsingClient) var parsingClient
                let parsedResponse = try await parsingClient.parseCaptchaUrl(rawString: rawString)
                return parsedResponse
            },
            authorize: { login, password, hidden, captcha in
                let request = LoginRequest(name: login, password: password, hidden: hidden, captcha: captcha)
                let rawString = try api.get(AuthCommand.login(data: request))
                @Dependency(\.parsingClient) var parsingClient
                let parsedResponse = try await parsingClient.parseLoginResponse(rawString: rawString)
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
            },
            getCaptcha: {
                try await Task.sleep(for: .seconds(2))
                return URL(string: "https://github.com/SubvertDev/ForPDA/raw/main/images/logo.png")!
            },
            authorize: { _, _, _, _ in
                return .success(userId: -1, token: "preview_token")
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
