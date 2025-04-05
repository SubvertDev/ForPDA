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
import FavoritesRootFeature
import HistoryFeature
import AuthFeature
import ProfileFeature
import QMSListFeature
import QMSFeature
import SettingsFeature
import NotificationsFeature
import DeveloperFeature
import ToastClient
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
                    StackTabView(store: store.scope(state: \.articlesTab, action: \.articlesTab))
                        .tag(AppTab.articles)

                    StackTabView(store: store.scope(state: \.favoritesTab, action: \.favoritesTab))
                        .tag(AppTab.favorites)
                    
                    StackTabView(store: store.scope(state: \.forumTab, action: \.forumTab))
                        .tag(AppTab.forum)
                    
                    StackTabView(store: store.scope(state: \.profileTab, action: \.profileTab))
                        .tag(AppTab.profile)
                }
                
                Group {
                    if store.showTabBar {
                        PDATabView()
                            .transition(.move(edge: .bottom))
                    }
                }
                // Animation on whole ZStack breaks safeareainset for next screens
                .animation(.default, value: store.showTabBar)
                
                if let toast = store.toastMessage {
                    Toast(toast)
                        .ignoresSafeArea(.keyboard, edges: .bottom)
                }
            }
            .animation(.default, value: store.toastMessage)
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
        .background(Color(.Background.primary))
        .clipShape(.rect(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))
        .shadow(color: Color(.Labels.primary).opacity(0.15), radius: 2)
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
            
            Text(title, bundle: .module)
                .font(.caption2)
        }
        .foregroundStyle(store.selectedTab.rawValue == index
                         ? store.appSettings.appTintColor.asColor
                         : Color(.Labels.quaternary))
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Toast (Refactor)
    
    @State private var isExpanded = false
    @State private var duration = 5

    @ViewBuilder
    private func Toast(_ toast: ToastMessage) -> some View {
        HStack(spacing: 0) {
            Image(systemSymbol: toast.isError ? .xmarkCircleFill : .checkmarkCircleFill)
                .font(.body)
                .foregroundStyle(toast.isError ? Color(.Main.red) : tintColor)
                .frame(width: 32, height: 32)
            
            if isExpanded {
                Text(toast.description, bundle: .toast)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.primary))
                    .padding(.trailing, 12)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .background(Color(.Background.primary))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.Separator.secondary), lineWidth: 0.33)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
        .padding(.bottom, 50 + 16)
        .padding(.horizontal, 16)
        .opacity(isExpanded ? 1 : 0)
        .task {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = true
            }
            
            try? await Task.sleep(for: .seconds(duration - 1))
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isExpanded = false
            }
            
            try? await Task.sleep(for: .seconds(0.4))
            store.send(.didFinishToastAnimation)
        }
    }
}

// MARK: - UINC edge swipe enable

extension UINavigationController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = nil
    }
}

// MARK: - Model Extensions

extension AppTintColor {
    var asColor: Color {
        switch self {
        case .primary:  Color(.Theme.primary)
        case .purple:   Color(.Theme.purple)
        case .lettuce:  Color(.Theme.lettuce)
        case .orange:   Color(.Theme.orange)
        case .pink:     Color(.Theme.pink)
        case .scarlet:  Color(.Theme.scarlet)
        case .sky:      Color(.Theme.sky)
        case .yellow:   Color(.Theme.yellow)
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
