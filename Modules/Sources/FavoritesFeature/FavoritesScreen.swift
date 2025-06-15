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
    @Environment(\.tintColor) private var tintColor
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Init

    public init(store: StoreOf<FavoritesFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()

                if store.shouldShowEmptyState {
                    EmptyFavorites()
                } else if !store.isLoading {
                    List {
                        if !store.favoritesImportant.isEmpty {
                            FavoritesSection(favorites: store.favoritesImportant, important: true)
                        }
                        
                        FavoritesSection(favorites: store.favorites, important: false)
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await send(.onRefresh).finish()
                    }
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text("Favorites", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .animation(.default, value: store.favoritesImportant)
            .animation(.default, value: store.favorites)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if store.isUserAuthorized {
                            Menu {
                                ContextButton(
                                    text: "Sort",
                                    symbol: .line3HorizontalDecrease,
                                    bundle: .module
                                ) {
                                    send(.contextOptionMenu(.sort))
                                }
                                
                                ContextButton(
                                    text: "Read All",
                                    symbol: .checkmarkCircle,
                                    bundle: .module
                                ) {
                                    send(.contextOptionMenu(.markAllAsRead))
                                }
                            } label: {
                                Image(systemSymbol: .ellipsisCircle)
                            }
                        }
                    }
                }
            }
            .fittedSheet(item: $store.scope(state: \.sort, action: \.sort)) { store in
                SortView(store: store)
            }
            .onChange(of: scenePhase) { newScenePhase in
                if (scenePhase == .inactive || scenePhase == .background) && newScenePhase == .active {
                    send(.onSceneBecomeActive)
                }
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
                    text: favorite.isImportant ? "From Important" : "To Important",
                    symbol: favorite.isImportant ? .heartFill : .heart,
                    bundle: .module
                ) {
                    send(.commonContextMenu(
                        .setImportant(favorite.topic.id, favorite.isImportant ? false : true),
                        favorite.isForum
                    ))
                }
            }
            
            Section {
                ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
                    send(.commonContextMenu(.copyLink(favorite.topic.id), favorite.isForum))
                }
                
                ContextButton(text: "Delete", symbol: .trash, bundle: .module) {
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
                    text: "Go To End",
                    symbol: .chevronRight2,
                    bundle: .module
                ) {
                    send(.topicContextMenu(.goToEnd, favorite))
                }
                
                ContextButton(
                    text: "Notify Hat Update",
                    symbol: favorite.isNotifyHatUpdate ? .flagFill : .flag,
                    bundle: .module
                ) {
                    send(.topicContextMenu(.notifyHatUpdate(favorite.flag), favorite))
                }
                
                Menu {
                    ContextButton(
                        text: "Always",
                        symbol: favorite.notify == .always ? .bellFill : .bell,
                        bundle: .module
                    ) {
                        send(.topicContextMenu(.notify(favorite.flag, .always), favorite))
                    }
                    
                    ContextButton(
                        text: "Once",
                        symbol: favorite.notify == .once ? .bellBadgeFill : .bellBadge,
                        bundle: .module
                    ) {
                        send(.topicContextMenu(.notify(favorite.flag, .once), favorite))
                    }
                    
                    ContextButton(
                        text: "Do Not",
                        symbol: favorite.notify == .doNot ? .bellSlashFill : .bellSlash,
                        bundle: .module
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
            Navigation(isShown: !important)
            
            ForEach(Array(favorites.enumerated()), id: \.element) { index, favorite in
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
                            title: favorite.topic.name,
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
                    if !favorite.isForum {
                        TopicContextMenu(favorite: favorite)
                    }
                    
                    Section {
                        CommonContextMenu(favorite: favorite)
                    }
                }
                .listRowBackground(
                    Color(.Background.teritary)
                        .clipShape(.rect(
                            topLeadingRadius: index == 0 ? 10 : 0, bottomLeadingRadius: index == favorites.count - 1 ? 10 : 0,
                            bottomTrailingRadius: index == favorites.count - 1 ? 10 : 0, topTrailingRadius: index == 0 ? 10 : 0
                        ))
                )
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            Navigation(isShown: !important)
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

#Preview {
    NavigationStack {
        FavoritesScreen(
            store: Store(
                initialState: FavoritesFeature.State(favorites: [.mock, .mockUnread])
            ) {
                FavoritesFeature()
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
    .tint(Color(.Theme.primary))
}
