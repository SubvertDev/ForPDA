//
//  APIClient.swift
//
//
//  Created by Ilia Lubianoi on 30.06.2024.
//

import Foundation
import Combine
import PDAPI
import Models
import ParsingClient
import CacheClient
import ComposableArchitecture
import PersistenceKeys

public typealias ConnectionState = API.ConnectionState
public typealias UploadProgressStatus = PDAPI.UploadProgressStatus
public typealias PDAPIError = APIError

// MARK: - Client

@DependencyClient
public struct APIClient: Sendable {
    
    // Common
    public var connect: @Sendable (_ inBackground: Bool) async throws -> Void
    public var disconnect: @Sendable () async throws -> Void
    public var setLogResponses: @Sendable (_ type: ResponsesLogType) -> Void
    
    // Articles
    public var getArticlesList: @Sendable (_ offset: Int, _ amount: Int) async throws -> [ArticlePreview]
    public var getArticle: @Sendable (_ id: Int, _ policy: CachePolicy) async throws -> AsyncThrowingStream<Article, any Error>
    public var likeComment: @Sendable (_ articleId: Int, _ commentId: Int) async throws -> Bool
    public var hideComment: @Sendable (_ articleId: Int, _ commentId: Int) async throws -> Bool
    public var replyToComment: @Sendable (_ articleId: Int, _ parentId: Int, _ message: String) async throws -> CommentResponseType
    public var voteInPoll: @Sendable (_ pollId: Int, _ selections: [Int]) async throws -> Bool
    
    // Auth
    public var getCaptcha: @Sendable () async throws -> URL
    public var authorize: @Sendable (_ login: String, _ password: String, _ hidden: Bool, _ captcha: Int) async throws -> AuthResponse
    public var logout: @Sendable () async throws -> Void
    
    // User
    public var getUser: @Sendable (_ userId: Int, _ policy: CachePolicy) async throws -> AsyncThrowingStream<User, any Error>
    public var editUserProfile: @Sendable (_ request: UserProfileEditRequest) async throws -> Bool
    public var getReputationVotes: @Sendable (_ data: ReputationVotesRequest) async throws -> ReputationVotes
    public var changeReputation: @Sendable (_ data: ReputationChangeRequest) async throws -> ReputationChangeResponseType
    public var updateUserAvatar: @Sendable (_ userId: Int, _ image: Data) async throws -> UserAvatarResponseType
    public var updateUserDevice: @Sendable (_ userId: Int, _ action: UserDeviceAction, _ fullTag: String, _ isPrimary: Bool) async throws -> Bool
    
    // Bookmarks
    public var getBookmarksList: @Sendable () async throws -> [Bookmark]
    
    // Forum
    public var getForumsList: @Sendable (_ policy: CachePolicy) async throws -> AsyncThrowingStream<[ForumInfo], any Error>
    public var getForum: @Sendable (_ id: Int, _ page: Int, _ perPage: Int, _ policy: CachePolicy) async throws -> AsyncThrowingStream<Forum, any Error>
    public var jumpForum: @Sendable (_ request: JumpForumRequest) async throws -> ForumJump
    public var markRead: @Sendable (_ id: Int, _ isTopic: Bool) async throws -> Bool
    public var getAnnouncement: @Sendable (_ id: Int) async throws -> Announcement
    public var getTopic: @Sendable (_ id: Int, _ page: Int, _ perPage: Int) async throws -> Topic
    public var getTemplate: @Sendable (_ request: ForumTemplateRequest, _ isTopic: Bool) async throws -> [WriteFormFieldType]
    public var getHistory: @Sendable (_ offset: Int, _ perPage: Int) async throws -> History
    public var previewPost: @Sendable (_ request: PostPreviewRequest) async throws -> PostPreview
    public var sendPost: @Sendable (_ request: PostRequest) async throws -> PostSendResponse
    public var editPost: @Sendable (_ request: PostEditRequest) async throws -> PostSendResponse
    public var deletePosts: @Sendable (_ postIds: [Int]) async throws -> Bool
    public var postKarma: @Sendable (_ postId: Int, _ isUp: Bool) async throws -> Bool
    public var voteInTopicPoll: @Sendable (_ topicId: Int, _ selections: [[Int]]) async throws -> Bool
    
    // Favorites
    public var getFavorites: @Sendable (_ request: FavoritesRequest, _ policy: CachePolicy) async throws -> AsyncThrowingStream<Favorite, any Error>
    public var setFavorite: @Sendable (_ request: SetFavoriteRequest) async throws -> Bool
    public var notifyFavorite: @Sendable (_ request: NotifyFavoriteRequest) async throws -> Bool
    public var readAllFavorites: @Sendable () async throws -> Bool
    
    // Extra
    public var getUnread: @Sendable (_ type: Int, _ value: Int) async throws -> Unread
    public var getAttachment: @Sendable (_ id: Int) async throws -> URL
    public var sendReport: @Sendable (_ request: ReportRequest) async throws -> ReportResponseType
    
    // QMS -> MOVED TO QMSCLIENT
    
    // STREAMS
    public var connectionState: @Sendable () -> AsyncStream<ConnectionState> = { .finished }
    public var notificationStream: @Sendable () -> AsyncStream<String> = { .finished }
    
    // UPLOAD
    public var upload: @Sendable (UploadRequest) -> AsyncStream<UploadProgressStatus> = { _ in .finished }
}

// MARK: - Dependency Key

extension APIClient: DependencyKey {
    
    public static let api = API()
    
    // MARK: - Live Value
    
    public static var liveValue: APIClient {
        @Dependency(\.cacheClient) var cache
        @Dependency(\.parsingClient) var parser

        return APIClient(
            
            // MARK: - Common
            
            connect: { inBackground in
                @Shared(.userSession) var userSession
                if let userSession {
                    let request = AuthRequest(memberId: userSession.userId, token: userSession.token, hidden: userSession.isHidden)
                    try await api.connect(as: .account(data: request), inBackground: inBackground)
                } else {
                    try await api.connect(as: .anonymous)
                }
            },
            
            disconnect: {
                api.disconnect()
            },
            
            setLogResponses: { type in
                api.setLogResponses(to: type)
            },
            
            // MARK: - Articles
            
            getArticlesList: { offset, amount in
                let response = try await api.send(SiteCommand.articlesList(offset: offset, amount: amount))
                return try await parser.parseArticlesList(response)
            },
            
            getArticle: { id, policy in
                fetch(
                    getCache: { await cache.getArticle(id) },
                    setCache: { await cache.setArticle($0) },
                    remote: {
                        let command = SiteCommand.article(id: id)
                        let response = try await api.send(command)
                        return try await parser.parseArticle(response)
                    },
                    policy: policy
                )
            },
            
            likeComment: { articleId, commentId in
                let response = try await api.send(SiteCommand.articleCommentLike(articleId: articleId, commentId: commentId))
                return Int(response.getResponseStatus()) == 0
            },
            
            hideComment: { articleId, commentId in
                let response = try await api.send(SiteCommand.articleCommentHide(articleId: articleId, commentId: commentId))
                // Getting 3 on liked comment
                return Int(response.getResponseStatus()) == 0
            },
            
            replyToComment: { articleId, parentId, message in
                let response = try await api.send(SiteCommand.articleComment(articleId: articleId, parentId: parentId, msg: message))
                let responseAsInt = Int(response.getResponseStatus())!
                if CommentResponseType.codes.contains(responseAsInt) {
                    return CommentResponseType(rawValue: responseAsInt) ?? .unknown
                } else {
                    return CommentResponseType.success
                }
            },
            
            voteInPoll: { pollId, selections in
                let response = try await api.send(SiteCommand.vote(pollId: pollId, selections: selections))
                let responseAsInt = Int(response.getResponseStatus())!
                return responseAsInt == 0
            },
            
            // MARK: - Auth
            
            getCaptcha: {
                let request = LoginRequest(name: "", password: "", hidden: false)
                let response = try await api.send(AuthCommand.login(data: request))
                return try await parser.parseCaptchaUrl(response)
            },
            
            authorize: { login, password, hidden, captcha in
                let request = LoginRequest(name: login, password: password, hidden: hidden, captcha: captcha)
                let response = try await api.send(AuthCommand.login(data: request))
                return try await parser.parseLogin(response)
            },
            
            logout: {
                let request = AuthRequest(memberId: 0, token: "", hidden: false)
                _ = try await api.send(AuthCommand.auth(data: request))
            },
            
            // MARK: - User
            
            getUser: { userId, policy in
                fetch(
                    getCache: { cache.getUser(userId) },
                    setCache: { await cache.setUser($0) },
                    remote: {
                        let command = MemberCommand.info(memberId: userId)
                        let response = try await api.send(command)
                        return try await parser.parseUser(response)
                    },
                    policy: policy
                )
            },
            editUserProfile: { request in
                let command = MemberCommand.profile(
                    data: MemberProfileRequest(
                        memberId: request.userId,
                        city: request.city,
                        gender: request.transferGender,
                        status: request.status,
                        about: request.about,
                        signature: request.signature,
                        birthday: request.birthdayDate
                    )
                )
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            getReputationVotes: { request in
                let command = MemberCommand.reputationVotes(data: MemberReputationVotesRequest(
                    memberId: request.userId,
                    type: request.transferType,
                    offset: request.offset,
                    count: request.amount
                ))
                let response = try await api.send(command)
                return try await parser.parseReputationVotes(response)
            },
            
            changeReputation: { request in
                let command = MemberCommand.reputation(data: MemberReputationRequest(
                    memberId: request.userId,
                    vote: request.transferVoteType,
                    postId: request.transferContentType,
                    reason: request.reason
                ))
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return ReputationChangeResponseType(rawValue: status)
            },
            updateUserAvatar: { userId, image in
                let command = MemberCommand.avatar(memberId: userId, avatar: image)
                let response = try await api.send(command)
                return try await parser.parseAvatarUrl(response: response)
            },
            updateUserDevice: { userId, action, fullTag, isPrimary in
                let action: MemberDeviceRequest.Action = switch action {
                case .add:    .add
                case .modify: .modify
                case .remove: .remove
                }
                let command = MemberCommand.device(data: MemberDeviceRequest(
                    memberId: userId,
                    action: action,
                    fullTag: fullTag,
                    primary: isPrimary
                ))
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            // MARK: - Bookmarks
            
            getBookmarksList: {
                let response = try await api.send(MemberCommand.Bookmarks.list)
                return try await parser.parseBookmarksList(response)
            },
            
            // MARK: - Forum
            
            getForumsList: { policy in
                fetch(
                    getCache: { await cache.getForumsList() },
                    setCache: { await cache.setForumsList($0) },
                    remote: {
                        let response = try await api.send(ForumCommand.list)
                        return try await parser.parseForumsList(response)
                    },
                    policy: policy
                )
            },
            
            getForum: { id, offset, perPage, policy in
                fetch(
                    getCache: { await cache.getForum(id) },
                    setCache: { await cache.setForum(id, $0) },
                    remote: {
                        let command = ForumCommand.view(id: id, offset: offset, itemsPerPage: perPage)
                        let response = try await api.send(command)
                        return try await parser.parseForum(response)
                    },
                    policy: policy
                )
            },
            
            jumpForum: { request in
                let command = ForumCommand.jump(data: ForumJumpRequest(
                    type: request.transferType,
                    postId: request.postId,
                    allPosts: request.allPosts,
                    topicId: request.topicId
                ))
                let response = try await api.send(command)
                return try await parser.parseForumJump(response)
            },
            
            markRead: { id, isTopic in
                let command = ForumCommand.markRead(id: id, isTopic: isTopic)
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            getAnnouncement: { id in
                let response = try await api.send(ForumCommand.announcement(linkId: id))
                return try await parser.parseAnnouncement(response)
            },
            
            getTopic: { id, offset, perPage in
                let request = TopicRequest(id: id, offset: offset, itemsPerPage: perPage, showPostMode: 1)
                let response = try await api.send(ForumCommand.Topic.view(data: request))
                return try await parser.parseTopic(response)
            },
            
            getTemplate: { request, isTopic in
                let command = ForumCommand.template(
                    type: isTopic ? .topic(forumId: request.id) : .post(topicId: request.id),
                    action: request.action.transferType
                )
                let response = try await api.send(command)
                return try await parser.parseWriteForm(response)
            },
            
			getHistory: { offset, perPage in
                let response = try await api.send(MemberCommand.history(page: offset, perPage: perPage))
                return try await parser.parseHistory(response)
            },
            
            previewPost: { request in
                let command = ForumCommand.Post.preview(data: PostSendRequest(
                    topicId: request.post.topicId,
                    content: request.post.content,
                    attaches: request.post.attachments,
                    flag: request.post.flag
                ), postId: request.id)
                let response = try await api.send(command)
                return try await parser.parsePostPreview(response)
            },
            
            sendPost: { request in
                let command = ForumCommand.Post.send(data: PostSendRequest(
                    topicId: request.topicId,
                    content: request.content,
                    attaches: request.attachments,
                    flag: request.flag
                ))
                let response = try await api.send(command)
                return try await parser.parsePostSendResponse(response)
            },
            
            editPost: { request in
                let command = ForumCommand.Post.edit(
                    data: PostSendRequest(
                        topicId: request.data.topicId,
                        content: request.data.content,
                        attaches: request.data.attachments,
                        flag: request.data.flag
                    ),
                    postId: request.postId,
                    reason: request.reason
                )
                let response = try await api.send(command)
                return try await parser.parsePostSendResponse(response)
			},
            
            deletePosts: { ids in
                let command = ForumCommand.Post.delete(postIds: ids)
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            postKarma: { id, isUp in
                let command = ForumCommand.Post.karma(
                    postId: id,
                    action: isUp ? .plus : .minus
                )
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            voteInTopicPoll: { topicId, selections in
                let command = ForumCommand.Topic.Poll.vote(topicId: topicId, selections: selections)
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            // MARK: - Favorites
            
            getFavorites: { request, policy in
                fetch(
                    getCache: { await cache.getFavorites() },
                    setCache: { await cache.setFavorites($0) },
                    remote: {
                        let command = MemberCommand.Favorites.list(
                            sort: request.transferSort,
                            offset: request.offset,
                            perPage: request.perPage
                        )
                        let response = try await api.send(command)
                        let favorites = try await parser.parseFavorites(response)
                        await cache.setFavorites(favorites)
                        return favorites
                    },
                    policy: policy
                )
            },
            
            setFavorite: { request in
                let command = MemberCommand.Favorites.modify(
                    id: request.id,
                    type: request.transferType,
                    action: request.transferAction
                )
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            notifyFavorite: { request in
                let command = MemberCommand.Favorites.notify(
                    id: request.id,
                    flag: request.flag,
                    new: request.transferType
                )
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            readAllFavorites: {
                let response = try await api.send(MemberCommand.Favorites.readAll)
                let status = Int(response.getResponseStatus())!
                return status == 0
            },
            
            // MARK: - Extra
            
            getUnread: { type, value in
                let response = try await api.send(CommonCommand.syncUnread(type: type, value: value))
                return try await parser.parseUnread(response)
            },
            
            getAttachment: { id in
                let stream = fetch(
                    getCache: { cache.getAttachmentURL(id) },
                    setCache: { cache.setAttachmentURL(id, $0) },
                    remote: {
                        let response = try await api.send(ForumCommand.attachmentDownloadUrl(id: id))
                        let urlString = String(response.dropFirst(10).dropLast(2))
                        return URL(string: urlString)!
                    },
                    policy: .cacheOrLoad
                )
                for try await url in stream { return url } // I was too lazy to conform to AsyncStream on callsite
                throw NSError(domain: "APIClient.getAttachment", code: 0)
            },
            
            sendReport: { request in
                let command = CommonCommand.report(
                    code: request.transferType,
                    id: request.id,
                    message: request.message
                )
                let response = try await api.send(command)
                let status = Int(response.getResponseStatus())!
                return ReportResponseType(rawValue: status)
            },
            
            // MARK: - Streams
            
            connectionState: {
                return api.stateStream
            },
            
            notificationStream: {
                return api.notificationStream
            },
            
            // MARK: - Upload
            
            upload: { request in
                return api.upload(request: request)
            }
        )
    }
    
    // MARK: - Preview Value
    
    public static var previewValue: APIClient {
        APIClient(
            connect: { _ in },
            disconnect: { },
            setLogResponses: { _ in },
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
            getUser: { _, _ in
                AsyncThrowingStream { $0.yield(.mock) }
            },
            editUserProfile: { _ in
                return true
            },
            getReputationVotes: { _ in
                return .mock
            },
            changeReputation: { _ in
                return .success
            },
            updateUserAvatar: { _, _ in
                return .success(URL(string: "https://github.com/SubvertDev/ForPDA/raw/main/Images/logo.png")!)
            },
            updateUserDevice: { _, _, _, _ in
                return true
            },
            getBookmarksList: {
                return [.mockArticle, .mockForum, .mockUser]
            },
            getForumsList: { _ in
                return .finished()
            },
            getForum: { _, _, _, _ in
                return .finished()
            },
            jumpForum: { _ in
                return .mock
            },
            markRead: { _, _ in
                return true
            },
            getAnnouncement: { _ in
                return .mock
            },
            getTopic: { _, _, _ in
                return .mock
            },
            getTemplate: { _, _ in
                return [.mockTitle, .mockText, .mockEditor]
            },
			getHistory: { _, _ in
                return .mock
			},
            previewPost: { request in
                return PostPreview(
                    content: request.post.content,
                    attachmentIds: request.post.attachments
                )
            },
            sendPost: { _ in
                return .success(PostSend(id: 0, topicId: 1, offset: 2))
            },
            editPost: { _ in
                return .success(PostSend(id: 0, topicId: 1, offset: 2))
			},
            deletePosts: { _ in
                return true
            },
            postKarma: { _, _ in
                return true
            },
            voteInTopicPoll: { _, _ in
                return true
            },
            getFavorites: { _, _ in
                let (stream, continuation) = AsyncThrowingStream.makeStream(of: Favorite.self)
                continuation.yield(with: .success(.mock))
                return stream
            },
            setFavorite: { _ in
                return true
            },
            notifyFavorite: { _ in
                return true
            },
            readAllFavorites: {
                return true
            },
            getUnread: { _, _ in
                return .mock
            },
            getAttachment: { _ in
                return URL(string: "/")!
            },
            sendReport: { _ in
                return .success
            },
            connectionState: {
                return .finished
            },
            notificationStream: {
                return .finished
            },
            upload: { _ in
                return .finished
            }
        )
    }
    
    // MARK: - Test Value
    
    public static let testValue = Self()
    
    // MARK: - Helper methods
    
    private static func fetch<T>(
        getCache: @Sendable @escaping () async -> T?,
        setCache: @Sendable @escaping (T) async -> Void,
        remote: @Sendable @escaping () async throws -> T,
        policy: CachePolicy
    ) -> AsyncThrowingStream<T, any Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    switch policy {
                    case .skipCache:
                        let remote = try await remote()
                        await setCache(remote)
                        continuation.yield(remote)
                        
                    case .cacheOrLoad:
                        if let cache = await getCache() {
                            continuation.yield(cache)
                        } else {
                            let remote = try await remote()
                            await setCache(remote)
                            continuation.yield(remote)
                        }
                        
                    case .cacheAndLoad:
                        if let cache = await getCache() {
                            continuation.yield(cache)
                        }
                        let remote = try await remote()
                        await setCache(remote)
                        continuation.yield(remote)
                        
                    case .cacheNoLoad:
                        if let cache = await getCache() {
                            continuation.yield(cache)
                        }
                    }
                } catch {
                    continuation.finish(throwing: error)
                    return
                }
                
                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
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
    func getResponseStatus() -> String {
        return self
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .components(separatedBy: ",")[1]
    }
}
