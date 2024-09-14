//
//  AppSettings.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import Foundation

public enum ArticleListRowType: String, Sendable, Equatable, Codable {
    case normal
    case short
    
    public static func toggle(from state: ArticleListRowType) -> ArticleListRowType {
        if state == ArticleListRowType.normal {
            return ArticleListRowType.short
        } else {
            return ArticleListRowType.normal
        }
    }
}

public struct AppSettings: Sendable, Equatable, Codable {
    
    public var articlesListRowType: ArticleListRowType
    public var bookmarksListRowType: ArticleListRowType
    
    public init(
        articlesListRowType: ArticleListRowType,
        bookmarksListRowType: ArticleListRowType
    ) {
        self.articlesListRowType = articlesListRowType
        self.bookmarksListRowType = bookmarksListRowType
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.articlesListRowType = try container.decodeIfPresent(ArticleListRowType.self, forKey: .articlesListRowType) ?? AppSettings.default.articlesListRowType
        self.bookmarksListRowType = try container.decodeIfPresent(ArticleListRowType.self, forKey: .bookmarksListRowType) ?? AppSettings.default.bookmarksListRowType
    }
}

public extension AppSettings {
    static let `default` = AppSettings(
        articlesListRowType: .normal,
        bookmarksListRowType: .normal
    )
}
