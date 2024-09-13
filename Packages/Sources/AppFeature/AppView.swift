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
import SFSafeSymbols
import SharedUI

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
    @Environment(\.tintColor) var tintColor
    @State var currentTintColor = Color.Theme.primary
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                TabView(selection: $store.selectedTab) {
                    ArticlesListTab()
                    ForumTab()
                    ForumTab()
                    ProfileTab()
                }
                .toolbar(.hidden, for: .tabBar)
                
                PDATabView()
//                .toast(isPresenting: $store.showToast) {
//                    AlertToast(displayMode: .hud, type: .regular, title: store.toast.message, bundle: store.localizationBundle)
//                }
            }
            .tint(currentTintColor)
//            .environment(\.tintColor, currentTintColor)
        }
    }
    
    // MARK: - Articles List Tab
    
    @State private var animateTab = false
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
                Image(systemSymbol: .docTextImage)
                    .bounceUpByLayerEffect(value: animateTab)
            }
        }
        .onAppear {
            animateTab.toggle()
        }
        .tag(Tab.articlesList)
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
                Image(systemSymbol: .bubbleLeftAndBubbleRight)
            }
        }
        .tag(Tab.forum)
    }
    
    // MARK: - Menu Tab
    
    @ViewBuilder
    private func ProfileTab() -> some View {
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
                Text("Profile", bundle: .module)
            } icon: {
                Image(systemSymbol: .personCropCircle)
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
                        store.selectedTab = tab
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
        .shadow(color: Color.black.opacity(0.15), radius: 2)
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
        .foregroundStyle(store.selectedTab.rawValue == index ? currentTintColor : Color.Labels.quaternary)
        .frame(maxWidth: .infinity)
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
