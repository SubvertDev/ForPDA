//
//  ParsingClient.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import ComposableArchitecture
import Models

@DependencyClient
public struct ParsingClient: Sendable {
    public var parseArticlesList: @Sendable (_ rawString: String) async throws -> [ArticlePreview]
    public var parseArticle: @Sendable (_ rawString: String) async throws -> Article
    public var parseArticleElements: @Sendable (_ article: Article) async throws -> [ArticleElement]
    public var parseCaptchaUrl: @Sendable (_ rawString: String) async throws -> URL
    public var parseLoginResponse: @Sendable (_ rawString: String) async throws -> AuthResponse
    public var parseUser: @Sendable (_ rawString: String) async throws -> User
    public var parseForumsList: @Sendable (_ rawString: String) async throws -> [ForumInfo]
    public var parseForum: @Sendable (_ rawString: String) async throws -> Forum
    public var parseTopic: @Sendable (_ rawString: String) async throws -> Topic
    public var parseAnnouncement: @Sendable (_ rawString: String) async throws -> Announcement
    public var parseFavorites: @Sendable (_ rawString: String) async throws -> Favorite
    public var parseUnread: @Sendable (_ rawString: String) async throws -> Unread
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
        },
        parseUser: { rawString in
            return try ProfileParser.parseUser(rawString: rawString)
        },
        parseForumsList: { rawString in
            return try ForumParser.parseForumList(rawString: rawString)
        },
        parseForum: { rawString in
            return try ForumParser.parse(rawString: rawString)
        },
        parseTopic: { rawString in
            return try TopicParser.parse(rawString: rawString)
        },
        parseAnnouncement: { rawString in
            return try ForumParser.parseAnnouncement(rawString: rawString)
        },
        parseFavorites: { rawString in
            return try FavoriteParser.parse(rawString: rawString)
        },
        parseUnread: { rawString in
            return try UnreadParser.parse(rawString: rawString)
        }
    )
}
