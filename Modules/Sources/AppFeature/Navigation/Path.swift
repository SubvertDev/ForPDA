//
//  Path.swift
//  AppFeature
//
//  Created by Ilia Lubianoi on 30.03.2025.
//

import SwiftUI
import ComposableArchitecture
import AnnouncementFeature
import ArticleFeature
import ArticlesListFeature
import DeveloperFeature
import FavoritesRootFeature
import ForumFeature
import ForumsListFeature
import HistoryFeature
import NotificationsFeature
import ProfileFeature
import QMSFeature
import QMSListFeature
import ReputationFeature
import SearchResultFeature
import SettingsFeature
import TopicFeature
import AuthFeature

@Reducer(state: .equatable)
public enum Path {
    case articles(Articles.Body = Articles.body)
    case favorites(FavoritesRootFeature)
    case forum(Forum.Body = Forum.body)
    case profile(Profile.Body = Profile.body)
    case settings(Settings.Body = Settings.body)
    case qms(QMS.Body = QMS.body)
    case auth(AuthFeature)
    
    @Reducer(state: .equatable)
    public enum Articles {
        case articlesList(ArticlesListFeature)
        case article(ArticleFeature)
    }
    
    @Reducer(state: .equatable)
    public enum Profile {
        case profile(ProfileFeature)
        case history(HistoryFeature)
        case reputation(ReputationFeature)
    }
    
    @Reducer(state: .equatable)
    public enum Forum {
        case forumList(ForumsListFeature)
        case forum(ForumFeature)
        case announcement(AnnouncementFeature)
        case topic(TopicFeature)
        case search(SearchResultFeature)
    }
    
    @Reducer(state: .equatable)
    public enum Settings {
        case settings(SettingsFeature)
        case navigation(NavigationSettingsFeature)
        case notifications(NotificationsFeature)
        case developer(DeveloperFeature)
    }
    
    @Reducer(state: .equatable)
    public enum QMS {
        case qmsList(QMSListFeature)
        case qms(QMSFeature)
    }
}

extension Path {
    @MainActor @ViewBuilder
    public static func view(_ store: Store<Path.State, Path.Action>) -> some View {
        switch store.case {
        case let .articles(path):
            ArticlesViews(path)
            
        case let .favorites(store):
            FavoritesRootScreen(store: store)
                .tracking(for: FavoritesRootScreen.self)
            
        case let .profile(path):
            ProfileViews(path)
            
        case let .forum(path):
            ForumViews(path)
            
        case let .settings(path):
            SettingsViews(path)
            
        case let .qms(path):
            QMSViews(path)
            
        case let .auth(store):
            AuthScreen(store: store)
                .tracking(for: AuthScreen.self)
        }
    }
    
    @MainActor @ViewBuilder
    private static func ArticlesViews(_ store: Store<Path.Articles.State, Path.Articles.Action>) -> some View {
        switch store.case {
        case let .articlesList(store):
            ArticlesListScreen(store: store)
                .tracking(for: ArticlesListScreen.self)
            
        case let .article(store):
            ArticleScreen(store: store)
                .tracking(for: ArticleScreen.self, ["id": store.articlePreview.id])
        }
    }
    
    @MainActor @ViewBuilder
    private static func ProfileViews(_ store: Store<Path.Profile.State, Path.Profile.Action>) -> some View {
        switch store.case {
        case let .profile(store):
            ProfileScreen(store: store)
                .tracking(for: ProfileScreen.self, ["id": store.userId ?? 0])

        case let .history(store):
            HistoryScreen(store: store)
                .tracking(for: HistoryScreen.self)
            
        case let .reputation(store):
            ReputationScreen(store: store)
                .tracking(for: ReputationScreen.self)
        }
    }
    
    @MainActor @ViewBuilder
    private static func ForumViews(_ store: Store<Path.Forum.State, Path.Forum.Action>) -> some View {
        switch store.case {
        case let .forumList(store):
            ForumsListScreen(store: store)
                .tracking(for: ForumsListScreen.self)
            
        case let .search(store):
            SearchResultScreen(store: store)
                .tracking(for: SearchResultScreen.self)
            
        case let .forum(store):
            ForumScreen(store: store)
                .tracking(for: ForumScreen.self, ["id": store.forumId])
            
        case let .topic(store):
            TopicScreen(store: store)
                .tracking(for: TopicScreen.self, ["id": store.topicId])
            
        case let .announcement(store):
            AnnouncementScreen(store: store)
                .tracking(for: AnnouncementScreen.self, ["id": store.announcementId])
        }
    }
    
    @MainActor @ViewBuilder
    private static func SettingsViews(_ store: Store<Path.Settings.State, Path.Settings.Action>) -> some View {
        switch store.case {
        case let .settings(store):
            SettingsScreen(store: store)
                .tracking(for: SettingsScreen.self)
            
        case let .navigation(store):
            NavigationSettingsScreen(store: store)
                .tracking(for: NavigationSettingsScreen.self)
            
        case let .notifications(store):
            NotificationsScreen(store: store)
                .tracking(for: NotificationsScreen.self)
            
        case let .developer(store):
            DeveloperScreen(store: store)
                .tracking(for: DeveloperScreen.self)
        }
    }
    
    @MainActor @ViewBuilder
    private static func QMSViews(_ store: Store<Path.QMS.State, Path.QMS.Action>) -> some View {
        switch store.case {
        case let .qmsList(store):
            QMSListScreen(store: store)
                .tracking(for: QMSListScreen.self)
            
        case let .qms(store):
            QMSScreen(store: store)
                .tracking(for: QMSScreen.self)
        }
    }
}
