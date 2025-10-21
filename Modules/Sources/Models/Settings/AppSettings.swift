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
    public var topicOpeningStrategy: TopicOpeningStrategy
    public var appColorScheme: AppColorScheme
    public var backgroundTheme: BackgroundTheme
    public var appTintColor: AppTintColor
    public var notifications: NotificationsSettings
    public var favorites: FavoritesSettings
    public var forumPerPage: Int
    public var topicPerPage: Int
    public var historyPerPage: Int
    public var floatingNavigation: Bool
    public var analyticsConfigurationDebug: AnalyticsConfiguration
    public var analyticsConfigurationRelease: AnalyticsConfiguration
    
    public init(
        articlesListRowType: ArticleListRowType,
        bookmarksListRowType: ArticleListRowType,
        startPage: AppTab,
        topicOpeningStrategy: TopicOpeningStrategy,
        appColorScheme: AppColorScheme,
        backgroundTheme: BackgroundTheme,
        appTintColor: AppTintColor,
        notifications: NotificationsSettings,
        favorites: FavoritesSettings,
        forumPerPage: Int,
        topicPerPage: Int,
        historyPerPage: Int,
        floatingNavigation: Bool,
        analyticsConfigurationDebug: AnalyticsConfiguration,
        analyticsConfigurationRelease: AnalyticsConfiguration
    ) {
        self.articlesListRowType = articlesListRowType
        self.bookmarksListRowType = bookmarksListRowType
        self.startPage = startPage
        self.topicOpeningStrategy = topicOpeningStrategy
        self.appColorScheme = appColorScheme
        self.backgroundTheme = backgroundTheme
        self.appTintColor = appTintColor
        self.notifications = notifications
        self.favorites = favorites
        self.forumPerPage = forumPerPage
        self.topicPerPage = topicPerPage
        self.historyPerPage = historyPerPage
        self.floatingNavigation = floatingNavigation
        self.analyticsConfigurationDebug = analyticsConfigurationDebug
        self.analyticsConfigurationRelease = analyticsConfigurationRelease
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.articlesListRowType = try container.decodeIfPresent(ArticleListRowType.self, forKey: .articlesListRowType) ?? AppSettings.default.articlesListRowType
        self.bookmarksListRowType = try container.decodeIfPresent(ArticleListRowType.self, forKey: .bookmarksListRowType) ?? AppSettings.default.bookmarksListRowType
        self.startPage = try container.decodeIfPresent(AppTab.self, forKey: .startPage) ?? AppSettings.default.startPage
        self.topicOpeningStrategy = try container.decodeIfPresent(TopicOpeningStrategy.self, forKey: .topicOpeningStrategy) ?? AppSettings.default.topicOpeningStrategy
        self.appColorScheme = try container.decodeIfPresent(AppColorScheme.self, forKey: .appColorScheme) ?? AppSettings.default.appColorScheme
        self.backgroundTheme = try container.decodeIfPresent(BackgroundTheme.self, forKey: .backgroundTheme) ?? AppSettings.default.backgroundTheme
        self.appTintColor = try container.decodeIfPresent(AppTintColor.self, forKey: .appTintColor) ?? AppSettings.default.appTintColor
        self.notifications = try container.decodeIfPresent(NotificationsSettings.self, forKey: .notifications) ?? AppSettings.default.notifications
        self.favorites = try container.decodeIfPresent(FavoritesSettings.self, forKey: .favorites) ?? AppSettings.default.favorites
        self.forumPerPage = try container.decodeIfPresent(Int.self, forKey: .forumPerPage) ?? AppSettings.default.forumPerPage
        self.topicPerPage = try container.decodeIfPresent(Int.self, forKey: .topicPerPage) ?? AppSettings.default.topicPerPage
        self.historyPerPage = try container.decodeIfPresent(Int.self, forKey: .historyPerPage) ?? AppSettings.default.historyPerPage
        self.floatingNavigation = try container.decodeIfPresent(Bool.self, forKey: .floatingNavigation) ?? AppSettings.default.floatingNavigation
        self.analyticsConfigurationDebug = try container.decodeIfPresent(AnalyticsConfiguration.self, forKey: .analyticsConfigurationDebug) ?? AppSettings.default.analyticsConfigurationDebug
        self.analyticsConfigurationRelease = try container.decodeIfPresent(AnalyticsConfiguration.self, forKey: .analyticsConfigurationRelease) ?? AppSettings.default.analyticsConfigurationRelease
    }
}

public extension AppSettings {
    static let `default` = AppSettings(
        articlesListRowType: .short,
        bookmarksListRowType: .short,
        startPage: .articles,
        topicOpeningStrategy: .first,
        appColorScheme: .system,
        backgroundTheme: .blue,
        appTintColor: .primary,
        notifications: .default,
        favorites: .default,
        forumPerPage: 30,
        topicPerPage: 20,
        historyPerPage: 20,
        floatingNavigation: true,
        analyticsConfigurationDebug: .debug,
        analyticsConfigurationRelease: .release
    )
}
