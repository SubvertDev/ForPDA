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
import ForumFeature
import MenuFeature
import AuthFeature
import ProfileFeature
import SettingsFeature
import AlertToast
import SFSafeSymbols
import SharedUI
import Models

public struct AppView: View {
    
    public enum Tab: Int, CaseIterable {
        case articlesList = 0
        case bookmarks
        case forum
        case profile
        
        var title: LocalizedStringKey {
            switch self {
            case .articlesList:
                return "Feed"
            case .bookmarks:
                return "Bookmarks"
            case .forum:
                return "Forum"
            case .profile:
                return "Profile"
            }
        }
        
        var iconSymbol: SFSymbol {
            switch self {
            case .articlesList:
                return .docTextImage
            case .bookmarks:
                return .bookmark
            case .forum:
                return .bubbleLeftAndBubbleRight
            case .profile:
                return .personCropCircle
            }
        }
    }
    
    @Perception.Bindable public var store: StoreOf<AppFeature>
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
                    BookmarksTab()
                    ForumTab()
                    ProfileTab()
                }
                
                PDATabView()
                    .offset(y: store.isShowingTabBar ? 0 : 84)
                    .animation(.default, value: store.isShowingTabBar)
//                .toast(isPresenting: $store.showToast) {
//                    AlertToast(displayMode: .hud, type: .regular, title: store.toast.message, bundle: store.localizationBundle)
//                }
            }
            .preferredColorScheme(store.appSettings.appColorScheme.asColorScheme)
            .fullScreenCover(item: $store.scope(state: \.auth, action: \.auth)) { store in
                NavigationStack {
                    AuthScreen(store: store)
                }
            }
            // Tint and environment should be after sheets/covers
            .tint(store.appSettings.appTintColor.asColor)
            .environment(\.tintColor, store.appSettings.appTintColor.asColor)
        }
    }
    
    // MARK: - Articles List Tab
    
    @ViewBuilder
    private func ArticlesListTab() -> some View {
        NavigationStack(path: $store.scope(state: \.articlesPath, action: \.articlesPath)) {
            ArticlesListScreen(store: store.scope(state: \.articlesList, action: \.articlesList))
        } destination: { store in
            switch store.case {
            case let .article(store):
                ArticleScreen(store: store)
                
            case let .profile(store):
                ProfileScreen(store: store)
                
            case let .settings(store):
                SettingsScreen(store: store)
            }
        }
        .tag(Tab.articlesList)
    }
    
    // MARK: - Bookmarks Tab
    
    @ViewBuilder
    private func BookmarksTab() -> some View {
        NavigationStack(path: $store.scope(state: \.bookmarksPath, action: \.bookmarksPath)) {
            BookmarksScreen(store: store.scope(state: \.bookmarks, action: \.bookmarks))
        } destination: { store in
            switch store.case {
            case let .settings(store):
                SettingsScreen(store: store)
            }
        }
        .tag(Tab.bookmarks)
    }
    
    // MARK: - Forum Tab
    
    @ViewBuilder
    private func ForumTab() -> some View {
        NavigationStack(path: $store.scope(state: \.forumPath, action: \.forumPath)) {
            ForumScreen(store: store.scope(state: \.forum, action: \.forum))
        } destination: { store in
            switch store.case {
            case let .settings(store):
                SettingsScreen(store: store)
            }
        }
        .tag(Tab.forum)
    }
    
    // MARK: - Menu Tab
    
    @ViewBuilder
    private func ProfileTab() -> some View {
        NavigationStack(path: $store.scope(state: \.profilePath, action: \.profilePath)) {
            ProfileScreen(store: store.scope(state: \.profile, action: \.profile))
        } destination: { store in
            switch store.case {
            case let .settings(store):
                SettingsScreen(store: store)
            }
        }
        .tag(Tab.profile)
    }
    
    // MARK: - PDA Tab View
    
    @ViewBuilder
    private func PDATabView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.self) { tab in
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
        .offset(y: 34)
    }
    
    // MARK: - PDA Tab Item
    
    @ViewBuilder
    private func PDATabItem(title: LocalizedStringKey, iconSymbol: SFSymbol, index: Int) -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: iconSymbol)
                .font(.body)
                .bounceUpByLayerEffect(value: shouldAnimatedTabItem[index])
                .frame(width: 32, height: 32)
            Text(title, bundle: .module)
                .font(.caption2)
        }
        .foregroundStyle(store.selectedTab.rawValue == index
                         ? store.appSettings.appTintColor.asColor
                         : Color.Labels.quaternary)
        .frame(maxWidth: .infinity)
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
