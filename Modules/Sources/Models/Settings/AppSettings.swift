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
    public var backgroundNotifications2: Bool
    public var backupServer: Bool
    public var favorites: FavoritesSettings
    public var searchSort: SearchSort
    public var forumPerPage: Int
    public var topicPerPage: Int
    public var historyPerPage: Int
    public var mentionsPerPage: Int
    public var hideTabBarOnScroll: Bool
    public var floatingNavigation: Bool
    public var experimentalFloatingNavigation: Bool
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
        backgroundNotifications2: Bool,
        backupServer: Bool,
        favorites: FavoritesSettings,
        searchSort: SearchSort,
        forumPerPage: Int,
        topicPerPage: Int,
        historyPerPage: Int,
        mentionsPerPage: Int,
        hideTabBarOnScroll: Bool,
        floatingNavigation: Bool,
        experimentalFloatingNavigation: Bool,
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
        self.backgroundNotifications2 = backgroundNotifications2
        self.backupServer = backupServer
        self.favorites = favorites
        self.searchSort = searchSort
        self.forumPerPage = forumPerPage
        self.topicPerPage = topicPerPage
        self.historyPerPage = historyPerPage
        self.mentionsPerPage = mentionsPerPage
        self.hideTabBarOnScroll = hideTabBarOnScroll
        self.floatingNavigation = floatingNavigation
        self.experimentalFloatingNavigation = experimentalFloatingNavigation
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
        self.backgroundNotifications2 = try container.decodeIfPresent(Bool.self, forKey: .backgroundNotifications2) ?? AppSettings.default.backgroundNotifications2
        self.backupServer = try container.decodeIfPresent(Bool.self, forKey: .backupServer) ?? AppSettings.default.backupServer
        self.favorites = try container.decodeIfPresent(FavoritesSettings.self, forKey: .favorites) ?? AppSettings.default.favorites
        self.searchSort = try container.decodeIfPresent(SearchSort.self, forKey: .searchSort) ?? AppSettings.default.searchSort
        self.forumPerPage = try container.decodeIfPresent(Int.self, forKey: .forumPerPage) ?? AppSettings.default.forumPerPage
        self.topicPerPage = try container.decodeIfPresent(Int.self, forKey: .topicPerPage) ?? AppSettings.default.topicPerPage
        self.historyPerPage = try container.decodeIfPresent(Int.self, forKey: .historyPerPage) ?? AppSettings.default.historyPerPage
        self.mentionsPerPage = try container.decodeIfPresent(Int.self, forKey: .mentionsPerPage) ?? AppSettings.default.mentionsPerPage
        self.hideTabBarOnScroll = try container.decodeIfPresent(Bool.self, forKey: .hideTabBarOnScroll) ?? AppSettings.default.hideTabBarOnScroll
        self.floatingNavigation = try container.decodeIfPresent(Bool.self, forKey: .floatingNavigation) ?? AppSettings.default.floatingNavigation
        self.experimentalFloatingNavigation = try container.decodeIfPresent(Bool.self, forKey: .experimentalFloatingNavigation) ?? AppSettings.default.experimentalFloatingNavigation
        self.analyticsConfigurationDebug = try container.decodeIfPresent(AnalyticsConfiguration.self, forKey: .analyticsConfigurationDebug) ?? AppSettings.default.analyticsConfigurationDebug
        self.analyticsConfigurationRelease = try container.decodeIfPresent(AnalyticsConfiguration.self, forKey: .analyticsConfigurationRelease) ?? AppSettings.default.analyticsConfigurationRelease
    }
    
    // _rawValue is a temporary hotfix because conforming to String breaks backward-compatibility
    // Those who conformed before this dictionary, can use vanilla rawValue
    public func asDictionary() -> [String: Any] {
        let dictionary: [String: Any] = [
            "articlesListRowType": articlesListRowType.rawValue,
            "bookmarksListRowType": bookmarksListRowType.rawValue,
            "startPage": startPage.rawValue,
            "topicOpeningStrategy": topicOpeningStrategy._rawValue,
            "appColorScheme": appColorScheme._rawValue,
            "backgroundTheme": backgroundTheme._rawValue,
            "appTintColor": appTintColor._rawValue,
            "notifications": notifications.asDictionary(),
            "backgroundNotifications": backgroundNotifications2,
            "backupServer": backupServer,
            "favorites": favorites.asDictionary(),
            "searchSort": searchSort._rawValue,
            "hideTabBarOnScroll": hideTabBarOnScroll,
            "floatingNavigation": floatingNavigation,
            "experimentalFloatingNavigation": experimentalFloatingNavigation,
        ]
        return ["settings": dictionary]
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
        backgroundNotifications2: true,
        backupServer: false,
        favorites: .default,
        searchSort: .relevance,
        forumPerPage: 30,
        topicPerPage: 20,
        historyPerPage: 20,
        mentionsPerPage: 20,
        hideTabBarOnScroll: true,
        floatingNavigation: true,
        experimentalFloatingNavigation: false,
        analyticsConfigurationDebug: .debug,
        analyticsConfigurationRelease: .release
    )
}
