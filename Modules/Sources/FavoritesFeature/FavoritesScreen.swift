//
//  FavoritesScreen.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import SFSafeSymbols
import SharedUI
import Models

@ViewAction(for: FavoritesFeature.self)
public struct FavoritesScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<FavoritesFeature>
    @State private var navigationMinimized = false
    @Environment(\.tintColor) private var tintColor
    
    private var shouldShowNavigation: Bool {
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return store.pageNavigation.shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    private var isLegacyFloatingNavigationEnabled: Bool {
        return isLiquidGlass
        && store.appSettings.floatingNavigation
        && !store.appSettings.experimentalFloatingNavigation
    }
    
    // MARK: - Init

    public init(store: StoreOf<FavoritesFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            SlackList(LocalizedStringResource("Favorites", bundle: .module)) {
                WithPerceptionTracking {
                    if store.isLoading {
                        FavoritesSection(favorites: Favorite.mockLoading.favorites, important: false)
                            .redacted(reason: .placeholder)
                            .disabled(true)
                    } else {
                        if !store.favoritesImportant.isEmpty {
                            FavoritesSection(favorites: store.favoritesImportant, important: true)
                        }
                        FavoritesSection(favorites: store.favorites, important: false)
                    }
                }
            }
            .onRefresh {
                await send(.onRefresh).finish()
            }
            ._inScrollContentDetector(isEnabled: isLegacyFloatingNavigationEnabled, state: $navigationMinimized)
            .overlay {
                if store.shouldShowEmptyState {
                    EmptyFavorites()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isLegacyFloatingNavigationEnabled {
                    PageNavigation(
                        store: store.scope(state: \.pageNavigation, action: \.pageNavigation),
                        minimized: $navigationMinimized
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .animation(.default, value: store.isLoading)
            .animation(.default, value: store.shouldShowEmptyState)
            .animation(.default, value: store.favoritesImportant)
            .animation(.default, value: store.favorites)
            .disabled(store.shouldShowEmptyState)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !store.isLoading, !store.shouldShowEmptyState, store.isUserAuthorized {
                        Menu {
                            ContextButton(
                                text: LocalizedStringResource("Sort", bundle: .module),
                                symbol: .line3HorizontalDecrease
                            ) {
                                send(.contextOptionMenu(.sort))
                            }
                            
                            ContextButton(
                                text: LocalizedStringResource("Read All", bundle: .module),
                                symbol: .checkmarkCircle
                            ) {
                                send(.contextOptionMenu(.markAllAsRead))
                            }
                        } label: {
                            Image(systemSymbol: .ellipsisCircle)
                        }
                    }
                }
            }
            .fittedSheet(
                item: $store.scope(state: \.sort, action: \.sort),
                embedIntoNavStack: true
            ) { store in
                SortView(store: store)
            }
            .onFirstAppear {
                send(.onFirstAppear)
            } onNextAppear: {
                send(.onNextAppear)
            }
        }
    }
    
    // MARK: - Options Menu
    
    private func CommonContextMenu(favorite: FavoriteInfo) -> some View {
        VStack(spacing: 0) {
            Section {
                ContextButton(
                    text: favorite.isImportant
                    ? LocalizedStringResource("From Important", bundle: .module)
                    : LocalizedStringResource("To Important", bundle: .module),
                    symbol: favorite.isImportant ? .heartFill : .heart
                ) {
                    send(.commonContextMenu(
                        .setImportant(favorite.topic.id, favorite.isImportant ? false : true),
                        favorite.isForum
                    ))
                }
                
                if favorite.topic.isUnread {
                    ContextButton(
                        text: LocalizedStringResource("Mark As Read", bundle: .module),
                        symbol: .checkmarkCircle
                    ){
                        send(.commonContextMenu(.markRead(favorite.id), favorite.isForum))
                    }
                }
            }
            
            Section {
                ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                    send(.commonContextMenu(.copyLink(favorite.topic.id), favorite.isForum))
                }
                
                ContextButton(text: LocalizedStringResource("Delete", bundle: .module), symbol: .trash) {
                    send(.commonContextMenu(.delete(favorite.topic.id), favorite.isForum))
                }
            }
        }
    }
    
    // MARK: - Topic Context Menu
    
    private func TopicContextMenu(favorite: FavoriteInfo) -> some View {
        VStack(spacing: 0) {
            Section {
                ContextButton(
                    text: LocalizedStringResource("Go To End", bundle: .module),
                    symbol: .chevronRight2
                ) {
                    send(.topicContextMenu(.goToEnd, favorite))
                }
                
                ContextButton(
                    text: LocalizedStringResource("Notify Hat Update", bundle: .module),
                    symbol: favorite.isNotifyHatUpdate ? .flagFill : .flag
                ) {
                    send(.topicContextMenu(.notifyHatUpdate(favorite.flag), favorite))
                }
                
                Menu {
                    ContextButton(
                        text: LocalizedStringResource("Always", bundle: .module),
                        symbol: favorite.notify == .always ? .bellFill : .bell
                    ) {
                        send(.topicContextMenu(.notify(favorite.flag, .always), favorite))
                    }
                    
                    ContextButton(
                        text: LocalizedStringResource("Once", bundle: .module),
                        symbol: favorite.notify == .once ? .bellBadgeFill : .bellBadge
                    ) {
                        send(.topicContextMenu(.notify(favorite.flag, .once), favorite))
                    }
                    
                    ContextButton(
                        text: LocalizedStringResource("Do Not", bundle: .module),
                        symbol: favorite.notify == .doNot ? .bellSlashFill : .bellSlash
                    ) {
                        send(.topicContextMenu(.notify(favorite.flag, .doNot), favorite))
                    }
                } label: {
                    HStack {
                        Text("Notify Type", bundle: .module)
                        NotifyTypeIcon(type: favorite.notify)
                    }
                }
            }
        }
    }
    
    // MARK: - Favorites Section
    
    @ViewBuilder
    private func FavoritesSection(favorites: [FavoriteInfo], important: Bool) -> some View {
        Section {
            if shouldShowNavigation {
                Navigation(isShown: !important)
            }
            
            ForEach(Array(favorites.enumerated()), id: \.element) { index, favorite in
                let radius: CGFloat = isLiquidGlass ? 24 : 10
                Group {
                    if favorite.isForum {
                        ForumRow(
                            title: favorite.topic.name,
                            isUnread: favorite.topic.isUnread,
                            onAction: {
                                send(.favoriteTapped(favorite, showUnread: false))
                            }
                        )
                    } else {
                        TopicRow(
                            title: .plain(favorite.topic.name),
                            date: favorite.topic.lastPost.date,
                            username: favorite.topic.lastPost.username,
                            isClosed: favorite.topic.isClosed,
                            isUnread: favorite.topic.isUnread,
                            onAction: { unreadTapped in
                                send(.favoriteTapped(favorite, showUnread: unreadTapped))
                            }
                        )
                    }
                }
                .contextMenu {
                    WithPerceptionTracking {
                        if !store.isLoading {
                            if !favorite.isForum {
                                TopicContextMenu(favorite: favorite)
                            }
                            
                            Section {
                                CommonContextMenu(favorite: favorite)
                            }
                        }
                    }
                }
                .listRowBackground(
                    Color(.Background.teritary)
                        .clipShape(
                            .rect(
                                topLeadingRadius: index == 0 ? radius : 0,
                                bottomLeadingRadius: index == favorites.count - 1 ? radius : 0,
                                bottomTrailingRadius: index == favorites.count - 1 ? radius : 0,
                                topTrailingRadius: index == 0 ? radius : 0
                            )
                        )
                )
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if shouldShowNavigation {
                Navigation(isShown: !important)
            }
        } header: {
            if !favorites.isEmpty {
                Header(title: important
                       ? LocalizedStringKey("Important")
                       : LocalizedStringKey("Topics / Forums"))
            }
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation(isShown: Bool) -> some View {
        if isShown, store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .listRowBackground(Color.clear)
                .padding(.bottom, 4)
        }
    }
    
    // MARK: - Notify Type Icon
    
    @ViewBuilder
    private func NotifyTypeIcon(type: FavoriteInfo.Notify) -> some View {
        let icon: SFSymbol = switch type {
        case .always: .bellFill
        case .once: .bellBadgeFill
        case .doNot: .bellSlashFill
        }

        Image(systemSymbol: icon)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.subheadline)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .offset(x: -16)
            .padding(.bottom, 4)
    }
    
    //MARK: - Empty View
    
    @ViewBuilder
    private func EmptyFavorites() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .bookmark)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("No favorites", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundColor(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text("Save something from the forum here", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                .padding(.horizontal, 55)
        }
    }
}

// MARK: - Previews

#Preview("Favorites") {
    @Shared(.userSession) var userSession
    $userSession.withLock { $0 = .mock }
    
    return NavigationStack {
        FavoritesScreen(
            store: Store(
                initialState: FavoritesFeature.State()
            ) {
                FavoritesFeature()
            } withDependencies: {
                $0.apiClient.getFavorites = { @Sendable _, _ in
                    return AsyncThrowingStream { continuation in
                        Task {
                            try? await Task.sleep(for: .seconds(1))
                            continuation.yield(with: .success(.mockTwoPages))
                            continuation.finish()
                        }
                    }
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
    .tint(Color(.Theme.primary))
}

#Preview("Favorites Loading") {
    @Shared(.userSession) var userSession
    $userSession.withLock { $0 = .mock }
    
    return NavigationStack {
        FavoritesScreen(
            store: Store(
                initialState: FavoritesFeature.State()
            ) {
                FavoritesFeature()
            } withDependencies: {
                $0.apiClient.getFavorites = { @Sendable _, _ in
                    return AsyncThrowingStream { _ in }
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
    .tint(Color(.Theme.primary))
}

#Preview("Favorites Empty") {
    NavigationStack {
        FavoritesScreen(
            store: Store(
                initialState: FavoritesFeature.State()
            ) {
                FavoritesFeature()
            } withDependencies: {
                $0.apiClient.getFavorites = { @Sendable _, _ in
                    return AsyncThrowingStream { continuation in
                        continuation.yield(with: .success(.mockEmpty))
                    }
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
    .tint(Color(.Theme.primary))
}
