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
import CacheClient
import ComposableArchitecture
import PersistenceKeys

@DependencyClient
public struct APIClient: Sendable {
    public var setLogResponses: @Sendable (_ type: ResponsesLogType) async -> Void
    public var connect: @Sendable () async throws -> Void
    public var getArticlesList: @Sendable (_ offset: Int, _ amount: Int) async throws -> [ArticlePreview]
    public var getArticle: @Sendable (_ id: Int) async throws -> AsyncThrowingStream<Article, any Error>
    public var likeComment: @Sendable (_ articleId: Int, _ commentId: Int) async throws -> Bool
    public var getCaptcha: @Sendable () async throws -> URL
    public var authorize: @Sendable (_ login: String, _ password: String, _ hidden: Bool, _ captcha: Int) async throws -> AuthResponse
    public var getUser: @Sendable (_ userId: Int) async throws -> AsyncThrowingStream<User, any Error>
}

extension APIClient: DependencyKey {
    
    private nonisolated(unsafe) static let api = try! PDAPI()
    
    public static var liveValue: APIClient {
        APIClient(
            setLogResponses: { type in
                api.setLogResponses(to: type)
            },
            connect: {
                @Shared(.userSession) var userSession
                if let userSession {
                    let request = AuthRequest(memberId: userSession.userId, token: userSession.token, hidden: userSession.isHidden)
                    try api.connect(as: .account(data: request))
                } else {
                    try api.connect(as: .anonymous)
                }
            },
            getArticlesList: { offset, amount in
                let rawString = try api.get(SiteCommand.articlesList(offset: offset, amount: amount))
                @Dependency(\.parsingClient) var parsingClient
                let articleList = try await parsingClient.parseArticlesList(rawString: rawString)
                return articleList
            },
            getArticle: { id in
                AsyncThrowingStream { continuation in
                    Task {
                        do {
                            @Dependency(\.cacheClient) var cacheClient
                            if let article = await cacheClient.getArticle(id) {
                                continuation.yield(article)
                            }
                            
                            @Dependency(\.parsingClient) var parsingClient
                            let rawString = try api.get(SiteCommand.article(id: id))
                            let article = try await parsingClient.parseArticle(rawString: rawString)
                            
                            try await cacheClient.cacheArticle(article)
                            continuation.yield(article)
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                }
            },
            likeComment: { articleId, commentId in
                let rawString = try api.get(SiteCommand.articleCommentLike(articleId: articleId, commentId: commentId))
                // TODO: Parse
                let response = rawString
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .components(separatedBy: ",")[1]
                return Int(response) == 0
            },
            getCaptcha: {
                let request = LoginRequest(name: "", password: "", hidden: false)
                let rawString = try api.get(AuthCommand.login(data: request))
                @Dependency(\.parsingClient) var parsingClient
                let url = try await parsingClient.parseCaptchaUrl(rawString: rawString)
                return url
            },
            authorize: { login, password, hidden, captcha in
                let request = LoginRequest(name: login, password: password, hidden: hidden, captcha: captcha)
                let rawString = try api.get(AuthCommand.login(data: request))
                @Dependency(\.parsingClient) var parsingClient
                let authResponse = try await parsingClient.parseLoginResponse(rawString: rawString)
                return authResponse
            },
            getUser: { userId in
                AsyncThrowingStream { continuation in
                    Task {
                        do {
                            @Dependency(\.cacheClient) var cacheClient
                            if let user = await cacheClient.getUser(userId) {
                                continuation.yield(user)
                            }
                            
                            @Dependency(\.parsingClient) var parsingClient
                            let rawString = try api.get(MemberCommand.info(memberId: userId))
                            let user = try await parsingClient.parseUser(rawString: rawString)
                            
                            try await cacheClient.cacheUser(user)
                            continuation.yield(user)
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                }
            }
        )
    }
    
    public static var previewValue: APIClient {
        APIClient(
            setLogResponses: { _ in },
            connect: { },
            getArticlesList: { _, _ in
                return Array(repeating: .mock, count: 30)
            },
            getArticle: { _ in
                AsyncThrowingStream { $0.yield(.mock) }
            },
            likeComment: { _, _ in
                return true
            },
            getCaptcha: {
                try await Task.sleep(for: .seconds(2))
                return URL(string: "https://github.com/SubvertDev/ForPDA/raw/main/images/logo.png")!
            },
            authorize: { _, _, _, _ in
                return .success(userId: -1, token: "preview_token")
            },
            getUser: { _ in
                AsyncThrowingStream { $0.yield(.mock) }
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
