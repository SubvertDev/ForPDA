//
//  AppSettings.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import Foundation

public struct AppSettings: Sendable, Equatable, Codable {
    
    public enum ArticleListRowType: String, Sendable, Equatable, Codable {
        case normal, short
        
        public static func toggle(from state: ArticleListRowType) -> ArticleListRowType {
            return state == ArticleListRowType.normal ? ArticleListRowType.short : ArticleListRowType.normal
        }
    }
    
    public var articlesListRowType: ArticleListRowType
    public var bookmarksListRowType: ArticleListRowType
    public var startPage: AppTab
    public var appColorScheme: AppColorScheme
    public var backgroundTheme: BackgroundTheme
    public var appTintColor: AppTintColor
    public var forumPerPage: Int
    public var topicPerPage: Int
    
    public init(
        articlesListRowType: ArticleListRowType,
        bookmarksListRowType: ArticleListRowType,
        startPage: AppTab,
        appColorScheme: AppColorScheme,
        backgroundTheme: BackgroundTheme,
        appTintColor: AppTintColor,
        forumPerPage: Int,
        topicPerPage: Int
    ) {
        self.articlesListRowType = articlesListRowType
        self.bookmarksListRowType = bookmarksListRowType
        self.startPage = startPage
        self.appColorScheme = appColorScheme
        self.backgroundTheme = backgroundTheme
        self.appTintColor = appTintColor
        self.forumPerPage = forumPerPage
        self.topicPerPage = topicPerPage
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.articlesListRowType = try container.decodeIfPresent(ArticleListRowType.self, forKey: .articlesListRowType) ?? AppSettings.default.articlesListRowType
        self.bookmarksListRowType = try container.decodeIfPresent(ArticleListRowType.self, forKey: .bookmarksListRowType) ?? AppSettings.default.bookmarksListRowType
        self.startPage = try container.decodeIfPresent(AppTab.self, forKey: .startPage) ?? AppSettings.default.startPage
        self.appColorScheme = try container.decodeIfPresent(AppColorScheme.self, forKey: .appColorScheme) ?? AppSettings.default.appColorScheme
        self.backgroundTheme = try container.decodeIfPresent(BackgroundTheme.self, forKey: .backgroundTheme) ?? AppSettings.default.backgroundTheme
        self.appTintColor = try container.decodeIfPresent(AppTintColor.self, forKey: .appTintColor) ?? AppSettings.default.appTintColor
        self.forumPerPage = try container.decodeIfPresent(Int.self, forKey: .forumPerPage) ?? AppSettings.default.forumPerPage
        self.topicPerPage = try container.decodeIfPresent(Int.self, forKey: .topicPerPage) ?? AppSettings.default.topicPerPage
    }
}

public extension AppSettings {
    static let `default` = AppSettings(
        articlesListRowType: .short,
        bookmarksListRowType: .short,
        startPage: .articlesList,
        appColorScheme: .system,
        backgroundTheme: .blue,
        appTintColor: .primary,
        forumPerPage: 30,
        topicPerPage: 20
    )
}
