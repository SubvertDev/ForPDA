//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import SwiftUI
import ComposableArchitecture
import ArticlesListFeature
import ArticleFeature
import BookmarksFeature
import ForumsListFeature
import ForumFeature
import TopicFeature
import AnnouncementFeature
import FavoritesFeature
import HistoryFeature
import MenuFeature
import AuthFeature
import ProfileFeature
import QMSListFeature
import QMSFeature
import SettingsFeature
import NotificationsFeature
import DeveloperFeature
import AlertToast
import SFSafeSymbols
import SharedUI
import Models

public struct AppView: View {
    
    @Perception.Bindable public var store: StoreOf<AppFeature>
    @Environment(\.tintColor) private var tintColor
    @State private var shouldAnimatedTabItem: [Bool] = [false, false, false, false]
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
        
        let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
        
    public var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                TabView(selection: $store.selectedTab) {
                    ArticlesListTab()
//                    BookmarksTab()
                    FavoritesTab()
                    ForumTab()
                    ProfileTab()
                }
                
                Group {
                    if store.isShowingTabBar {
                        PDATabView()
                            .transition(.move(edge: .bottom))
                    }
                }
                // Animation on whole ZStack breaks safeareainset for next screens
                .animation(.default, value: store.isShowingTabBar)
                
                if store.showToast {
                    Toast()
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
                
                // Models Bundle load fix, do NOT delete
                Color.doNotDeleteMe.frame(width: 0, height: 0)
            }
            .animation(.default, value: store.showToast)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .preferredColorScheme(store.appSettings.appColorScheme.asColorScheme)
            .fullScreenCover(item: $store.scope(state: \.auth, action: \.auth)) { store in
                NavigationStack {
                    AuthScreen(store: store)
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            // Tint and environment should be after sheets/covers
            .tint(store.appSettings.appTintColor.asColor)
            .environment(\.tintColor, store.appSettings.appTintColor.asColor)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    // MARK: - Articles List Tab
    
    @ViewBuilder
    private func ArticlesListTab() -> some View {
        NavigationStack(
            path: $store.scope(state: \.articlesPath, action: \.articlesPath)
        ) {
            ArticlesListScreen(store: store.scope(state: \.articlesList, action: \.articlesList))
        } destination: { store in
            switch store.case {
            case let .article(store):
                ArticleScreen(store: store)
                
            case let .profile(store):
                ProfileScreen(store: store)
                
            case let .settingsPath(path):
                SettingsPath(path)
            }
        }
        .tag(AppTab.articlesList)
        .toolbar(store.isShowingTabBar ? .visible : .hidden, for: .tabBar)
    }
    
    // MARK: - Bookmarks Tab
    
//    @ViewBuilder
//    private func BookmarksTab() -> some View {
//        NavigationStack(path: $store.scope(state: \.bookmarksPath, action: \.bookmarksPath)) {
//            BookmarksScreen(store: store.scope(state: \.bookmarks, action: \.bookmarks))
//        } destination: { store in
//            switch store.case {
//            case let .settings(store):
//                SettingsScreen(store: store)
//            }
//        }
//        .tag(Tab.bookmarks)
//        .toolbar(store.isShowingTabBar ? .visible : .hidden, for: .tabBar)
//    }
    
    // MARK: - Favorites Tab
    @ViewBuilder
    private func FavoritesTab() -> some View {
        NavigationStack(
            path: $store.scope(state: \.favoritesPath, action: \.favoritesPath)
        ) {
            FavoritesScreen(store: store.scope(state: \.favorites, action: \.favorites))
        } destination: { store in
            switch store.case {
            case let .settingsPath(path):
                SettingsPath(path)
            }
        }
        .tag(AppTab.favorites)
        .toolbar(store.isShowingTabBar ? .visible : .hidden, for: .tabBar)
    }
    
    // MARK: - Forum Tab
    
    @ViewBuilder
    private func ForumTab() -> some View {
        NavigationStack(
            path: $store.scope(state: \.forumPath, action: \.forumPath)
        ) {
            ForumsListScreen(store: store.scope(state: \.forumsList, action: \.forumsList))
        } destination: { store in
            switch store.case {
            case let .forum(store):
                ForumScreen(store: store)
            
            case let .topic(store):
                TopicScreen(store: store)
                
            case let .profile(store):
                ProfileScreen(store: store)
                
            case let .announcement(store):
                AnnouncementScreen(store: store)
                
            case let .settingsPath(path):
                SettingsPath(path)
            }
        }
        .tag(AppTab.forum)
        .toolbar(store.isShowingTabBar ? .visible : .hidden, for: .tabBar)
    }
    
    // MARK: - Profile Tab
    
    @ViewBuilder
    private func ProfileTab() -> some View {
        NavigationStack(
            path: $store.scope(state: \.profilePath, action: \.profilePath)
        ) {
            ProfileScreen(store: store.scope(state: \.profile, action: \.profile))
        } destination: { store in
            switch store.case {
            case let .history(store):
                HistoryScreen(store: store)
            case let .qmsPath(path):
                QMSPath(path)
            case let .settingsPath(path):
                SettingsPath(path)
            }
        }
        .tag(AppTab.profile)
        .toolbar(store.isShowingTabBar ? .visible : .hidden, for: .tabBar)
    }
    
    // MARK: - QMS Path
    
    @ViewBuilder
    private func QMSPath(_ store: StoreOf<AppFeature.QMSPath.Body>) -> some View {
        switch store.case {
        case let .qmsList(store):
            QMSListScreen(store: store)
        case let .qms(store):
            QMSScreen(store: store)
        }
    }
    
    // MARK: - Settings Path
    
    @ViewBuilder
    private func SettingsPath(_ store: StoreOf<AppFeature.SettingsPath.Body>) -> some View {
        switch store.case {
        case let .settings(store):
            SettingsScreen(store: store)
        case let .developer(store):
            DeveloperScreen(store: store)
        case let .notifications(store):
            NotificationsScreen(store: store)
        }
    }
    
    // MARK: - PDA Tab View
    
    @ViewBuilder
    private func PDATabView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        store.send(.didSelectTab(tab))
                        shouldAnimatedTabItem[tab.rawValue].toggle()
                    } label: {
                        PDATabItem(title: tab.title, iconSymbol: tab.iconSymbol, index: tab.rawValue)
                            .padding(.top, 2.5)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 84)
        .background(Color.Background.primary)
        .clipShape(.rect(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))
        .shadow(color: Color.Labels.primary.opacity(0.15), radius: 2)
        .offset(y: 34) // TODO: Check for different screens
    }
    
    // MARK: - PDA Tab Item
    
    @ViewBuilder
    private func PDATabItem(title: LocalizedStringKey, iconSymbol: SFSymbol, index: Int) -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: iconSymbol)
                .font(.body)
                .bounceUpByLayerEffect(value: shouldAnimatedTabItem[index])
                .frame(width: 32, height: 32)
            Text(title, bundle: .models)
                .font(.caption2)
        }
        .foregroundStyle(store.selectedTab.rawValue == index
                         ? store.appSettings.appTintColor.asColor
                         : Color.Labels.quaternary)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Toast
    
    @State private var duration = 5
    
    @ViewBuilder
    private func Toast() -> some View {
        HStack(spacing: 0) {
            Image(systemSymbol: store.toast.isError ? .xmarkCircleFill : .checkmarkCircleFill)
                .font(.body)
                .foregroundStyle(store.toast.isError ? Color.Main.red : tintColor)
                .frame(width: 32, height: 32)
            
            Text(store.toast.message, bundle: store.localizationBundle)
                .font(.caption)
                .foregroundStyle(Color.Labels.primary)
                .padding(.trailing, 12)
        }
        .background(Color.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.Separator.secondary, lineWidth: 0.33)
        }
        .padding(.bottom, 50 + 16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .task {
            try? await Task.sleep(for: .seconds(duration))
            store.showToast = false
        }
    }
}

// MARK: - Model Extensions

extension AppTintColor {
    var asColor: Color {
        switch self {
        case .primary:  Color.Theme.primary
        case .purple:   Color.Theme.purple
        case .lettuce:  Color.Theme.lettuce
        case .orange:   Color.Theme.orange
        case .pink:     Color.Theme.pink
        case .scarlet:  Color.Theme.scarlet
        case .sky:      Color.Theme.sky
        case .yellow:   Color.Theme.yellow
        }
    }
}

// MARK: - Previews

#Preview {
    AppView(
        store: Store(
            initialState: AppFeature.State()
        ) {
            AppFeature()
        }
    )
}
