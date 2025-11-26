//
//  ParsingClient.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import ComposableArchitecture
import Models

// MARK: - Client

@DependencyClient
public struct ParsingClient: Sendable {
    // Articles
    public var parseArticlesList: @Sendable (_ response: String) async throws -> [ArticlePreview]
    public var parseArticle: @Sendable (_ response: String) async throws -> Article
    public var parseArticleElements: @Sendable (_ article: Article) async throws -> [ArticleElement]
    
    // Auth
    public var parseCaptchaUrl: @Sendable (_ response: String) async throws -> URL
    public var parseLogin: @Sendable (_ response: String) async throws -> AuthResponse
    
    // User
    public var parseUser: @Sendable (_ response: String) async throws -> User
    public var parseReputationVotes: @Sendable ( _ response: String) async throws -> ReputationVotes
    public var parseAvatarUrl: @Sendable (_ response: String) async throws -> UserAvatarResponseType
    
    // Bookmarks
    public var parseBookmarksList: @Sendable (_ response: String) async throws -> [Bookmark]
    
    // Forum
    public var parseForumsList: @Sendable (_ response: String) async throws -> [ForumInfo]
    public var parseForumJump: @Sendable (_ response: String) async throws -> ForumJump
    public var parseForum: @Sendable (_ response: String) async throws -> Forum
    public var parseTopic: @Sendable (_ response: String) async throws -> Topic
    public var parseAnnouncement: @Sendable (_ response: String) async throws -> Announcement
    public var parseFavorites: @Sendable (_ response: String) async throws -> Favorite
    public var parseHistory: @Sendable (_ response: String) async throws -> History
    public var parsePostPreview: @Sendable (_ response: String) async throws -> PostPreview
    public var parsePostSendResponse: @Sendable (_ response: String) async throws -> PostSendResponse
    
    // Search
    public var parseSearch: @Sendable (_ response: String) async throws -> SearchResponse
    public var parseSearchUsers: @Sendable (_ response: String) async throws -> SearchUsersResponse
    
    // Write Form
    public var parseWriteForm: @Sendable (_ response: String) async throws -> [WriteFormFieldType]
    
    // Extra
    public var parseUnread: @Sendable (_ response: String) async throws -> Unread
    
    // QMS
    public var parseQmsList: @Sendable (_ response: String) async throws -> QMSList
    public var parseQmsUser: @Sendable (_ response: String) async throws -> QMSUser
    public var parseQmsChat: @Sendable (_ response: String) async throws -> QMSChat
}

// MARK: - Dependency Key

extension ParsingClient: DependencyKey {
    
    // MARK: - Live Value
    
    public static let liveValue = Self(
        parseArticlesList: { response in
            return try ArticlesListParser.parse(from: response)
        },
        parseArticle: { response in
            return try ArticleParser.parse(from: response)
        },
        parseArticleElements: { article in
            return try ArticleElementParser.parse(from: article)
        },
        parseCaptchaUrl: { response in
            return try AuthParser.parseCaptchaUrl(from: response)
        },
        parseLogin: { response in
            return try AuthParser.parseLoginResponse(from: response)
        },
        parseUser: { response in
            return try ProfileParser.parseUser(from: response)
        },
        parseReputationVotes: { response in
            return try ReputationParser.parse(from: response)
        },
        parseAvatarUrl: { response in
            return try ProfileParser.parseAvatarUrl(from: response)
        },
        parseBookmarksList: { response in
            return try BookmarksParser.parse(from: response)
        },
        parseForumsList: { response in
            return try ForumParser.parseForumList(from: response)
        },
        parseForumJump: { response in
            return try ForumParser.parseForumJump(from: response)
        },
        parseForum: { response in
            return try ForumParser.parse(from: response)
        },
        parseTopic: { response in
            return try TopicParser.parse(from: response)
        },
        parseAnnouncement: { response in
            return try ForumParser.parseAnnouncement(from: response)
        },
        parseFavorites: { response in
            return try FavoriteParser.parse(from: response)
        },
        parseHistory: { response in
            return try HistoryParser.parse(from: response)
        },
        parsePostPreview: { response in
            return try TopicParser.parsePostPreview(from: response)
        },
        parsePostSendResponse: { response in
            return try TopicParser.parsePostSendResponse(from: response)
        },
        parseSearch: { response in
            return try SearchParser.parse(from: response)
        },
        parseSearchUsers: { response in
            return try SearchUsersParser.parse(from: response)
        },
        parseWriteForm: { response in
            return try WriteFormParser.parse(from: response)
        },
        parseUnread: { response in
            return try UnreadParser.parse(from: response)
        },
        parseQmsList: { response in
            return try QMSListParser.parse(from: response)
        },
        parseQmsUser: { response in
            return try QMSUserParser.parse(from: response)
        },
        parseQmsChat: { response in
            return try QMSChatParser.parse(from: response)
        }
    )
}

// MARK: - Extensions

extension DependencyValues {
    public var parsingClient: ParsingClient {
        get { self[ParsingClient.self] }
        set { self[ParsingClient.self] = newValue }
    }
}
