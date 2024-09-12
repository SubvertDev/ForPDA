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
import ForumFeature
import MenuFeature
import AuthFeature
import ProfileFeature
import SettingsFeature
import AlertToast

public struct AppView: View {
    
    @Perception.Bindable public var store: StoreOf<AppFeature>
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            TabView {
                ArticlesListTab()
                
                ForumTab()
                
                MenuTab()
            }
            .toast(isPresenting: $store.showToast) {
                AlertToast(displayMode: .hud, type: .regular, title: store.toast.message, bundle: store.localizationBundle)
            }
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
            }
        }
        .tabItem {
            Label {
                Text("Articles", bundle: .module)
            } icon: {
                Image(systemSymbol: .newspaperFill)
            }
        }
    }
    
    // MARK: - Forum Tab
    
    @ViewBuilder
    private func ForumTab() -> some View {
        NavigationStack(path: $store.scope(state: \.forumPath, action: \.forumPath)) {
            ForumScreen(store: store.scope(state: \.forum, action: \.forum))
        } destination: { store in
            switch store.case {
            default:
                return EmptyView()
            }
        }
        .tabItem {
            Label {
                Text("Forum", bundle: .module)
            } icon: {
                Image(systemSymbol: .bubbleLeftAndBubbleRightFill)
            }
        }
    }
    
    // MARK: - Menu Tab
    
    @ViewBuilder
    private func MenuTab() -> some View {
        NavigationStack(path: $store.scope(state: \.menuPath, action: \.menuPath)) {
            MenuScreen(store: store.scope(state: \.menu, action: \.menu))
        } destination: { store in
            switch store.case {
            case let .auth(store):
                AuthScreen(store: store)
                
            case let .profile(store):
                ProfileScreen(store: store)
                
            case let .settings(store):
                SettingsScreen(store: store)
            }
        }
        .tabItem {
            Label {
                Text("Menu", bundle: .module)
            } icon: {
                Image(systemSymbol: .line3Horizontal)
            }
        }
    }
}

#Preview {
    AppView(
        store: Store(
            initialState: AppFeature.State()
        ) {
            AppFeature()
        }
    )
}
