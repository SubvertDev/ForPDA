//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 09.04.2024.
//

import AlertToast
import AnnouncementFeature
import ArticleFeature
import ArticlesListFeature
import AuthFeature
import BookmarksFeature
import ComposableArchitecture
import DeveloperFeature
import FavoritesFeature
import FavoritesRootFeature
import ForumFeature
import ForumsListFeature
import HistoryFeature
import Models
import NotificationsFeature
import ProfileFeature
import QMSFeature
import QMSListFeature
import SettingsFeature
import SFSafeSymbols
import SharedUI
import SwiftUI
import ToastClient
import TopicFeature

import PageNavigationFeature

public struct AppView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<AppFeature>
    @Environment(\.tintColor) private var tintColor
    
    let pageStore = StoreOf<PageNavigationFeature>.init(
        initialState: PageNavigationFeature.State(type: .topic),
        reducer: { PageNavigationFeature() }
    )
    
    // MARK: - Init
    
    public init(store: StoreOf<AppFeature>) {
        self.store = store
        
        let tabBarAppearance: UITabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - Body
        
    public var body: some View {
        WithPerceptionTracking {
            ZStack(alignment: .bottom) {
                if #available(iOS 26.0, *) {
                    LiquidTabView(store: store)
                } else {
                    OldTabView(store: store)
                }
                
                ToastView(toast: store.toastMessage)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
            .animation(.default, value: store.toastMessage)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .preferredColorScheme(store.appSettings.appColorScheme.asColorScheme)
            .sheet(item: $store.scope(state: \.logStore, action: \.logStore)) { store in
                LogStoreScreen(store: store)
            }
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
            .onShake {
                store.send(.onShake)
            }
        }
    }
}

// MARK: - Liquid Tab View

@available(iOS 26.0, *)
struct LiquidTabView: View {
    
    @Perception.Bindable var store: StoreOf<AppFeature>
    
    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.selectedTab.sending(\.didSelectTab)) {
                Tab(
                    AppTab.articles.title,
                    systemSymbol: AppTab.articles.iconSymbol,
                    value: .articles
                ) {
                    StackTabView(store: store.scope(state: \.articlesTab, action: \.articlesTab))
                }
                
                Tab(
                    AppTab.favorites.title,
                    systemSymbol: AppTab.favorites.iconSymbol,
                    value: .favorites
                ) {
                    StackTabView(store: store.scope(state: \.favoritesTab, action: \.favoritesTab))
                }
                
                Tab(
                    AppTab.forum.title,
                    systemSymbol: AppTab.forum.iconSymbol,
                    value: .forum
                ) {
                    StackTabView(store: store.scope(state: \.forumTab, action: \.forumTab))
                }
                
                Tab(
                    AppTab.profile.title,
                    systemSymbol: AppTab.profile.iconSymbol,
                    value: .profile
                ) {
                    ProfileTab(store: store.scope(state: \.profileFlow, action: \.profileFlow))
                }
            }
            .tabBarMinimizeBehavior(store.appSettings.hideTabBarOnScroll ? .onScrollDown : .never)
            .if(store.appSettings.experimentalFloatingNavigation) { content in
                content
                    .tabViewBottomAccessory {
                        BottomAccessory()
                    }
            }
        }
    }
    
    @ViewBuilder
    private func BottomAccessory() -> some View {
        switch store.selectedTab {
        case .articles:
            Page(for: store.scope(state: \.articlesTab, action: \.articlesTab))
        case .favorites:
            Page(for: store.scope(state: \.favoritesTab, action: \.favoritesTab))
        case .forum:
            Page(for: store.scope(state: \.forumTab, action: \.forumTab))
        case .profile:
            switch store.scope(state: \.profileFlow, action: \.profileFlow).case {
            case let .loggedIn(store), let .loggedOut(store):
                Page(for: store)
            }
        }
    }
    
    @ViewBuilder
    private func Page(for tab: Store<StackTab.State, StackTab.Action>) -> some View {
        if tab.path.isEmpty {
            _Page(for: tab.scope(state: \.root, action: \.root))
        } else if let id = tab.path.ids.last {
            if let path = tab.scope(state: \.path[id: id], action: \.path[id: id]) {
                _Page(for: path)
            }
        }
    }
    
    @ViewBuilder
    private func _Page(for store: Store<Path.State, Path.Action>) -> some View {
        switch store.case {
        case let .articles(path):
            switch path.case {
            case let .search(store):
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            default:
                EmptyView()
            }
        case let .favorites(store):
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
        case let .forum(path):
            switch path.case {
            case let .forum(store):
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            case let .topic(store):
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            case let .search(store):
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            default:
                EmptyView()
            }
        case let .profile(path):
            switch path.case {
            case let .history(store):
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            case let .search(store):
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            default:
                EmptyView()
            }
        default:
            EmptyView()
        }
    }
}

// MARK: - Old Tab View

@available(iOS, deprecated: 26.0, message: "Use LiquidTabView instead")
struct OldTabView: View {
    
    @Perception.Bindable var store: StoreOf<AppFeature>
    @State private var shouldAnimatedTabItem: [Bool] = [false, false, false, false]

    var body: some View {
        WithPerceptionTracking {
            TabView(selection: $store.selectedTab) {
                StackTabView(store: store.scope(state: \.articlesTab, action: \.articlesTab))
                    .tag(AppTab.articles)
                
                StackTabView(store: store.scope(state: \.favoritesTab, action: \.favoritesTab))
                    .tag(AppTab.favorites)
                
                StackTabView(store: store.scope(state: \.forumTab, action: \.forumTab))
                    .tag(AppTab.forum)
                
                ProfileTab(store: store.scope(state: \.profileFlow, action: \.profileFlow))
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
        }
    }
    
    // MARK: - PDA Tab Item
    
    @ViewBuilder
    private func PDATabItem(title: LocalizedStringResource, iconSymbol: SFSymbol, index: Int) -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: iconSymbol)
                .font(.body)
                .bounceUpByLayerEffect(value: shouldAnimatedTabItem[index])
                .frame(width: 32, height: 32)
            
            Text(title)
                .font(.caption2)
        }
        .foregroundStyle(store.selectedTab.rawValue == index
                         ? store.appSettings.appTintColor.asColor
                         : Color(.Labels.quaternary))
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - PDA Tab View
    
    @ViewBuilder
    private func PDATabView() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    WithPerceptionTracking {
                        Button {
                            store.send(.didSelectTab(tab))
                            shouldAnimatedTabItem[tab.rawValue].toggle()
                        } label: {
                            PDATabItem(title: tab.title, iconSymbol: tab.iconSymbol, index: tab.rawValue)
                                .padding(.top, 2.5)
                        }
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
}

// MARK: - Toast View

struct ToastView: View {
    
    @Environment(\.tintColor) private var tintColor
    
    @State private var isPresented = false
    @State private var isExpanded = true
    @State private var duration = 5
    @State private var pendingTask: Task<Void, Never>?
    @State private var lastToast: ToastMessage!
    
    let toast: ToastMessage?

    var body: some View {
        ZStack {
            if isPresented, let toast = lastToast {
                HStack(spacing: 0) {
                    Image(systemSymbol: toast.isError ? .xmarkCircleFill : .checkmarkCircleFill)
                        .font(.body)
                        .foregroundStyle(toast.isError ? Color(.Main.red) : tintColor)
                        .frame(width: 32, height: 32)
                    
                    if isExpanded {
                        Text(toast.text)
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
            }
        }
        .onChange(of: toast) { newValue in
            pendingTask?.cancel()
            
            if let newValue {
                withAnimation {
                    lastToast = newValue
                    isPresented = true
                }
            } else {
                pendingTask = Task {
                    try? await Task.sleep(for: .seconds(1))
                    guard !Task.isCancelled else { return }
                    withAnimation {
                        isPresented = false
                        lastToast = nil
                        pendingTask = nil
                    }
                }
            }
        }
    }
}

// MARK: - UINC edge swipe enable

extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 26.0, *) {
            // swipe works from any point if back button is not disabled
            // which is unnecessary with default luquid back button
        } else {
            // interactivePopGestureRecognizer?.delegate = nil
            interactivePopGestureRecognizer?.delegate = self
        }
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.isKind(of: UIScreenEdgePanGestureRecognizer.self)
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
