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

// MARK: - Client

@DependencyClient
public struct APIClient: Sendable {
    // Common
    public var setLogResponses: @Sendable (_ type: ResponsesLogType) async -> Void
    public var connect: @Sendable () async throws -> Void
    
    // Articles
    public var getArticlesList: @Sendable (_ offset: Int, _ amount: Int) async throws -> [ArticlePreview]
    public var getArticle: @Sendable (_ id: Int, _ useCache: Bool) async throws -> AsyncThrowingStream<Article, any Error>
    public var likeComment: @Sendable (_ articleId: Int, _ commentId: Int) async throws -> Bool
    public var hideComment: @Sendable (_ articleId: Int, _ commentId: Int) async throws -> Bool
    public var replyToComment: @Sendable (_ articleId: Int, _ parentId: Int, _ message: String) async throws -> CommentResponseType
    public var voteInPoll: @Sendable (_ pollId: Int, _ selections: [Int]) async throws -> Bool
    
    // Auth
    public var getCaptcha: @Sendable () async throws -> URL
    public var authorize: @Sendable (_ login: String, _ password: String, _ hidden: Bool, _ captcha: Int) async throws -> AuthResponse
    public var logout: @Sendable () async throws -> Void
    
    // User
    public var getUser: @Sendable (_ userId: Int) async throws -> AsyncThrowingStream<User, any Error>
    
    // Forum
    public var getForumsList: @Sendable () async throws -> [ForumInfo]
    public var getForum: @Sendable (_ id: Int, _ page: Int, _ perPage: Int) async throws -> Forum
    public var getAnnouncement: @Sendable (_ id: Int) async throws -> Announcement
    public var getTopic: @Sendable (_ id: Int, _ page: Int, _ perPage: Int) async throws -> Topic
    public var getFavorites: @Sendable (_ unreadFirst: Bool, _ offset: Int, _ perPage: Int) async throws -> AsyncThrowingStream<[FavoriteInfo], any Error>
    public var getHistory: @Sendable (_ offset: Int, _ perPage: Int) async throws -> History
    
    // Extra
    public var getUnread: @Sendable () async throws -> Unread
    
    // QMS
    public var loadQMSList: @Sendable () async throws -> QMSList
    public var loadQMSUser: @Sendable (_ id: Int) async throws -> QMSUser
    public var loadQMSChat: @Sendable (_ id: Int) async throws -> QMSChat
    public var sendQMSMessage: @Sendable (_ chatId: Int, _ message: String) async throws -> Void
}

// MARK: - Dependency Key

extension APIClient: DependencyKey {
    
    private nonisolated(unsafe) static let api = try! PDAPI()
    
    // MARK: - Live Value
    
    public static var liveValue: APIClient {
        @Dependency(\.cacheClient) var cache
        @Dependency(\.parsingClient) var parser

        return APIClient(
            
            // MARK: - Common
            
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
            
            // MARK: - Articles
            
            getArticlesList: { offset, amount in
                let response = try await api.get(SiteCommand.articlesList(offset: offset, amount: amount))
                return try await parser.parseArticlesList(response)
            },
            getArticle: { id, useCache in
                fetchWithCache(
                    cache: { if useCache { await cache.getArticle(id) } else { nil } },
                    remote: {
                        let response = try await api.get(SiteCommand.article(id: id))
                        let article = try await parser.parseArticle(response)
                        await cache.cacheArticle(article)
                        return article
                    }
                )
            },
            likeComment: { articleId, commentId in
                let response = try await api.get(SiteCommand.articleCommentLike(articleId: articleId, commentId: commentId))
                return Int(response.getLastNumber()) == 0
            },
            hideComment: { articleId, commentId in
                let response = try await api.get(SiteCommand.articleCommentHide(articleId: articleId, commentId: commentId))
                // Getting 3 on liked comment
                return Int(response.getLastNumber()) == 0
            },
            replyToComment: { articleId, parentId, message in
                let response = try await api.get(SiteCommand.articleComment(articleId: articleId, parentId: parentId, msg: message))
                let responseAsInt = Int(response.getLastNumber())!
                if CommentResponseType.codes.contains(responseAsInt) {
                    return CommentResponseType(rawValue: responseAsInt) ?? .unknown
                } else {
                    return CommentResponseType.success
                }
            },
            voteInPoll: { pollId, selections in
                let response = try await api.get(SiteCommand.vote(pollId: pollId, selections: selections))
                let responseAsInt = Int(response.getLastNumber())!
                return responseAsInt == 0
            },
            
            // MARK: - Auth
            
            getCaptcha: {
                let request = LoginRequest(name: "", password: "", hidden: false)
                let response = try await api.get(AuthCommand.login(data: request))
                return try await parser.parseCaptchaUrl(response)
            },
            authorize: { login, password, hidden, captcha in
                let request = LoginRequest(name: login, password: password, hidden: hidden, captcha: captcha)
                let response = try await api.get(AuthCommand.login(data: request))
                return try await parser.parseLogin(response)
            },
            logout: {
                let request = AuthRequest(memberId: 0, token: "", hidden: false)
                _ = try await api.get(AuthCommand.auth(data: request))
            },
            
            // MARK: - User
            
            getUser: { userId in
                fetchWithCache(
                    cache: { await cache.getUser(userId) },
                    remote: {
                        let response = try await api.get(MemberCommand.info(memberId: userId))
                        let user = try await parser.parseUser(response)
                        await cache.cacheUser(user)
                        return user
                    }
                )
            },
            
            // MARK: - Forum
            
            getForumsList: {
                let response = try await api.get(ForumCommand.list)
                return try await parser.parseForumsList(response)
            },
            getForum: { id, offset, perPage in
                let response = try await api.get(ForumCommand.view(id: id, offset: offset, itemsPerPage: perPage))
                return try await parser.parseForum(response)
            },
            getAnnouncement: { id in
                let response = try await api.get(ForumCommand.announcement(linkId: id))
                return try await parser.parseAnnouncement(response)
            },
            getTopic: { id, offset, perPage in
                let request = TopicRequest(id: id, offset: offset, itemsPerPage: perPage, showPostMode: 1)
                let response = try await api.get(ForumCommand.Topic.view(data: request))
                return try await parser.parseTopic(response)
            },
            getFavorites: { unreadFirst, offset, perPage in
                fetchWithCache(
                    cache: { await cache.getFavorites() },
                    remote: {
                        let command = MemberCommand.Favorites.list(unreadFirst: unreadFirst, offset: offset, perPage: perPage)
                        let response = try await api.get(command)
                        let favorites = try await parser.parseFavorites(response)
                        await cache.cacheFavorites(favorites.favorites)
                        return favorites.favorites
                    }
                )
            },
			getHistory: { offset, perPage in
                let response = try await api.get(MemberCommand.history(page: offset, perPage: perPage))
                return try await parser.parseHistory(response)
            },
            
            // MARK: - Extra
            
            getUnread: {
                let response = try await api.get(CommonCommand.syncUnread)
                return try await parser.parseUnread(response)
            },
            
            // MARK: - QMS
            
            loadQMSList: {
                let response = try await api.get(QMSCommand.list)
                return try await parser.parseQmsList(response)
            },
            loadQMSUser: { id in
                let response = try await api.get(QMSCommand.info(id: id))
                return try await parser.parseQmsUser(response)
            },
            loadQMSChat: { id in
                let request = QMSViewDialogRequest(dialogId: id, messageId: 0, limit: 0)
                let response = try await api.get(QMSCommand.Dialog.view(data: request))
                return try await parser.parseQmsChat(response)
            },
            sendQMSMessage: { chatId, message in
                let request = QMSSendMessageRequest(dialogId: chatId, message: message, fileList: [])
                let _ = try await api.get(QMSCommand.Message.send(data: request))
                // Returns chatId + new messageId
			}
        )
    }
    
    // MARK: - Preview Value
    
    public static var previewValue: APIClient {
        APIClient(
            setLogResponses: { _ in },
            connect: { },
            getArticlesList: { _, _ in
                return Array(repeating: .mock, count: 30)
            },
            getArticle: { _, _ in
                AsyncThrowingStream { $0.yield(.mock) }
            },
            likeComment: { _, _ in
                return true
            },
            hideComment: { _, _ in
                return true
            },
            replyToComment: { _, _, _ in
                return .success
            },
            voteInPoll: { _, _ in
                return true
            },
            getCaptcha: {
                try await Task.sleep(for: .seconds(2))
                return URL(string: "https://github.com/SubvertDev/ForPDA/raw/main/Images/logo.png")!
            },
            authorize: { _, _, _, _ in
                return .success(userId: -1, token: "preview_token")
            },
            logout: {
                
            },
            getUser: { _ in
                AsyncThrowingStream { $0.yield(.mock) }
            },
            getForumsList: {
                return [.mockCategory, .mock]
            },
            getForum: { _, _, _ in
                return .mock
            },
            getAnnouncement: { _ in
                return .mock
            },
            getTopic: { _, _, _ in
                return .mock
            },
            getFavorites: { _, _, _ in
                .finished()
            },
			getHistory: { _, _ in
                return .mock
			},
            getUnread: {
                return .mock
            },
            loadQMSList: {
                return QMSList(users: [])
            },
            loadQMSUser: { _ in
                return QMSUser(userId: 0, name: "", flag: 0, avatarUrl: nil, lastSeenOnline: .now, lastMessageDate: .now, unreadCount: 0, chats: [])
            },
            loadQMSChat: { _ in
                return QMSChat(id: 0, creationDate: .now, lastMessageDate: .now, name: "", partnerId: 0, partnerName: "", flag: 0, avatarUrl: nil, unknownId1: 0, totalCount: 0, unknownId2: 0, lastMessageId: 0, unreadCount: 0, messages: [])
            },
            sendQMSMessage: { _, _ in
                
            }
        )
    }
    
    // MARK: - Helper methods
    
    private static func fetchWithCache<T>(
        cache: @Sendable @escaping () async -> T?,
        remote: @Sendable @escaping () async throws -> T
    ) -> AsyncThrowingStream<T, any Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    if let cached = await cache() {
                        continuation.yield(cached)
                    }
                    let remoteData = try await remote()
                    continuation.yield(remoteData)
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                continuation.finish()
            }
        }
    }
}

// MARK: - Extensions

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}


extension String {
    func getLastNumber() -> String {
        return self
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .components(separatedBy: ",")
            .last!
    }
}
