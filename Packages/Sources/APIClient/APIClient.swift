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
    public var getArticle: @Sendable (_ id: Int, _ cache: Bool) async throws -> AsyncThrowingStream<Article, any Error>
    public var likeComment: @Sendable (_ articleId: Int, _ commentId: Int) async throws -> Bool
    public var hideComment: @Sendable (_ articleId: Int, _ commentId: Int) async throws -> Bool
    public var replyToComment: @Sendable (_ articleId: Int, _ parentId: Int, _ message: String) async throws -> CommentResponseType
    public var voteInPoll: @Sendable (_ pollId: Int, _ selections: [Int]) async throws -> Bool
    public var getCaptcha: @Sendable () async throws -> URL
    public var authorize: @Sendable (_ login: String, _ password: String, _ hidden: Bool, _ captcha: Int) async throws -> AuthResponse
    public var logout: @Sendable () async throws -> Void
    public var getUser: @Sendable (_ userId: Int) async throws -> AsyncThrowingStream<User, any Error>
    public var getForumsList: @Sendable () async throws -> [ForumInfo]
    public var getForum: @Sendable (_ id: Int, _ page: Int, _ perPage: Int) async throws -> Forum
    public var getTopic: @Sendable (_ id: Int, _ page: Int, _ perPage: Int) async throws -> Topic
    public var getFavorites: @Sendable (_ unreadFirst: Bool, _ offset: Int, _ perPage: Int) async throws -> Favorite
    public var getHistory: @Sendable (_ offset: Int, _ perPage: Int) async throws -> History
    public var getUnread: @Sendable () async throws -> Unread
    public var loadQMSList: @Sendable () async throws -> QMSList
    public var loadQMSUser: @Sendable (_ id: Int) async throws -> QMSUser
    public var loadQMSChat: @Sendable (_ id: Int) async throws -> QMSChat
    public var sendQMSMessage: @Sendable (_ chatId: Int, _ message: String) async throws -> Void
}

extension APIClient: DependencyKey {
    
    private nonisolated(unsafe) static let api = try! PDAPI()
    
    public static var liveValue: APIClient {
        @Dependency(\.parsingClient) var parsingClient

        return APIClient(
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
                let rawString = try await api.get(SiteCommand.articlesList(offset: offset, amount: amount))
                return try await parsingClient.parseArticlesList(rawString: rawString)
            },
            getArticle: { id, cache in
                AsyncThrowingStream { continuation in
                    Task {
                        do {
                            @Dependency(\.cacheClient) var cacheClient
                            if cache {
                                if let article = await cacheClient.getArticle(id) {
                                    continuation.yield(article)
                                }
                            }
                            
                            @Dependency(\.parsingClient) var parsingClient
                            let rawString = try await api.get(SiteCommand.article(id: id))
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
                let rawString = try await api.get(SiteCommand.articleCommentLike(articleId: articleId, commentId: commentId))
                return Int(rawString.getLastNumber()) == 0
            },
            hideComment: { articleId, commentId in
                let rawString = try await api.get(SiteCommand.articleCommentHide(articleId: articleId, commentId: commentId))
                // Getting 3 on liked comment
                return Int(rawString.getLastNumber()) == 0
            },
            replyToComment: { articleId, parentId, message in
                let rawString = try await api.get(SiteCommand.articleComment(articleId: articleId, parentId: parentId, msg: message))
                let responseAsInt = Int(rawString.getLastNumber())!
                if CommentResponseType.codes.contains(responseAsInt) {
                    return CommentResponseType(rawValue: responseAsInt) ?? .unknown
                } else {
                    return CommentResponseType.success
                }
            },
            voteInPoll: { pollId, selections in
                let rawString = try await api.get(SiteCommand.vote(pollId: pollId, selections: selections))
                let responseAsInt = Int(rawString.getLastNumber())!
                return responseAsInt == 0
            },
            getCaptcha: {
                let request = LoginRequest(name: "", password: "", hidden: false)
                let rawString = try await api.get(AuthCommand.login(data: request))
                return try await parsingClient.parseCaptchaUrl(rawString: rawString)
            },
            authorize: { login, password, hidden, captcha in
                let request = LoginRequest(name: login, password: password, hidden: hidden, captcha: captcha)
                let rawString = try await api.get(AuthCommand.login(data: request))
                return try await parsingClient.parseLoginResponse(rawString: rawString)
            },
            logout: {
                let request = AuthRequest(memberId: 0, token: "", hidden: false)
                _ = try await api.get(AuthCommand.auth(data: request))
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
                            let rawString = try await api.get(MemberCommand.info(memberId: userId))
                            let user = try await parsingClient.parseUser(rawString: rawString)
                            
                            try await cacheClient.cacheUser(user)
                            continuation.yield(user)
                            continuation.finish()
                        } catch {
                            continuation.finish(throwing: error)
                        }
                    }
                }
            },
            getForumsList: {
                let rawString = try await api.get(ForumCommand.list)
                return try await parsingClient.parseForumsList(rawString: rawString)
            },
            getForum: { id, offset, perPage in
                let rawString = try await api.get(ForumCommand.view(id: id, offset: offset, itemsPerPage: perPage))
                return try await parsingClient.parseForum(rawString: rawString)
            },
            getTopic: { id, offset, perPage in
                let request = TopicRequest(id: id, offset: offset, itemsPerPage: perPage, showPostMode: 1)
                let rawString = try await api.get(ForumCommand.Topic.view(data: request))
                return try await parsingClient.parseTopic(rawString: rawString)
            },
            getFavorites: { unreadFirst, offset, perPage in
                let rawString = try await api.get(MemberCommand.Favorites.list(unreadFirst: unreadFirst, offset: offset, perPage: perPage))
                return try await parsingClient.parseFavorites(rawString: rawString)
            },
			getHistory: { offset, perPage in
                let rawString = try await api.get(MemberCommand.history(page: offset, perPage: perPage))
                return try await parsingClient.parseHistory(rawString: rawString)
            },
            getUnread: {
                let rawString = try await api.get(CommonCommand.syncUnread)
                return try await parsingClient.parseUnread(rawString: rawString)
            },
            loadQMSList: {
                let rawString = try await api.get(QMSCommand.list)
//                let info = try await api.get(QMSCommand.info(id: 4056435))
//                print("info: \(info)")
                return try await parsingClient.parseQmsList(rawString: rawString)
            },
            loadQMSUser: { id in
                let rawString = try await api.get(QMSCommand.info(id: id))
                return try await parsingClient.parseQmsUser(rawString: rawString)
            },
            loadQMSChat: { id in
                let request = QMSViewDialogRequest(dialogId: id, messageId: 0, limit: 0)
                let rawString = try await api.get(QMSCommand.Dialog.view(data: request))
                return try await parsingClient.parseQmsChat(rawString: rawString)
            },
            sendQMSMessage: { chatId, message in
                let request = QMSSendMessageRequest(dialogId: chatId, message: message, fileList: [])
                let _ = try await api.get(QMSCommand.Message.send(data: request))
                // Returns chatId + new messageId
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
            getTopic: { _, _, _ in
                return .mock
            },
            getFavorites: { _, _, _ in
                return .mock
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

extension DependencyValues {
    public var apiClient: APIClient {
        get { self[APIClient.self] }
        set { self[APIClient.self] = newValue }
    }
}
