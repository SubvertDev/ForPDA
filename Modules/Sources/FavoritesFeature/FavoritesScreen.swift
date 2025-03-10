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

                if !store.isLoading {
                    List {
                        if !store.favoritesImportant.isEmpty {
                            FavoritesSection(favorites: store.favoritesImportant, important: true)
                        }
                        
                        FavoritesSection(favorites: store.favorites, important: false)
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await store.send(.onRefresh).finish()
                    }
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
                
                if store.shouldShowEmptyState {
                    EmptyFavorites()
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
                                    store.send(.contextOptionMenu(.sort))
                                }
                                
                                ContextButton(
                                    text: "Read All",
                                    symbol: .checkmarkCircle,
                                    bundle: .module
                                ) {
                                    store.send(.contextOptionMenu(.markAllAsRead))
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
                    store.send(.onSceneBecomeActive)
                }
            }
            .onAppear {
                store.send(.onAppear)
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
                    store.send(.commonContextMenu(
                        .setImportant(favorite.topic.id, favorite.isImportant ? false : true),
                        favorite.isForum
                    ))
                }
            }
            
            Section {
                ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
                    store.send(.commonContextMenu(.copyLink(favorite.topic.id), favorite.isForum))
                }
                
                ContextButton(text: "Delete", symbol: .trash, bundle: .module) {
                    store.send(.commonContextMenu(.delete(favorite.topic.id), favorite.isForum))
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
                    store.send(.topicContextMenu(.goToEnd, favorite.topic.id))
                }
                
                ContextButton(
                    text: "Notify Hat Update",
                    symbol: favorite.isNotifyHatUpdate ? .flagFill : .flag,
                    bundle: .module
                ) {
                    store.send(.topicContextMenu(.notifyHatUpdate(favorite.flag), favorite.topic.id))
                }
                
                Menu {
                    ContextButton(
                        text: "Always",
                        symbol: favorite.notify == .always ? .bellFill : .bell,
                        bundle: .module
                    ) {
                        store.send(.topicContextMenu(.notify(favorite.flag, .always), favorite.topic.id))
                    }
                    
                    ContextButton(
                        text: "Once",
                        symbol: favorite.notify == .once ? .bellBadgeFill : .bellBadge,
                        bundle: .module
                    ) {
                        store.send(.topicContextMenu(.notify(favorite.flag, .once), favorite.topic.id))
                    }
                    
                    ContextButton(
                        text: "Do Not",
                        symbol: favorite.notify == .doNot ? .bellSlashFill : .bellSlash,
                        bundle: .module
                    ) {
                        store.send(.topicContextMenu(.notify(favorite.flag, .doNot), favorite.topic.id))
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
            if !important, store.pageNavigation.shouldShow {
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            }
            
            ForEach(favorites, id: \.hashValue) { favorite in
                Row(
                    id: favorite.topic.id,
                    title: favorite.topic.name,
                    lastPost: favorite.topic.lastPost,
                    closed: favorite.topic.isClosed,
                    unread: favorite.topic.isUnread,
                    notify: favorite.notify
                ) { showUnread in
                    if showUnread {
                        store.send(.unreadTapped(id: favorite.topic.id))
                    } else {
                        store.send(
                            .favoriteTapped(
                                id: favorite.topic.id,
                                name: favorite.topic.name,
                                offset: 0,
                                postId: nil,
                                isForum: favorite.isForum
                            )
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
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if !important, store.pageNavigation.shouldShow {
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
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
    
    // MARK: - Row
        
    @ViewBuilder
    private func Row(
        id: Int,
        title: String,
        lastPost: TopicInfo.LastPost? = nil,
        closed: Bool = false,
        unread: Bool = false,
        notify: FavoriteInfo.Notify,
        action: @escaping (_ unreadTapped: Bool) -> Void
    ) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action(false)
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let lastPost {
                            Text(lastPost.formattedDate, bundle: .models)
                                .font(.caption)
                                .foregroundStyle(Color(.Labels.teritary))
                        }
                        
                        RichText(
                            text: AttributedString(title),
                            isSelectable: false,
                            font: .body,
                            foregroundStyle: Color(.Labels.primary)
                        )
                        
                        if let lastPost {
                            HStack(spacing: 4) {
                                Image(systemSymbol: .personCircle)
                                    .font(.caption)
                                    .foregroundStyle(Color(.Labels.secondary))
                                
                                RichText(
                                    text: AttributedString(lastPost.username),
                                    font: .caption,
                                    foregroundStyle: Color(.Labels.secondary)
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)

                    if unread {
                        Button {
                            action(true)
                        } label: {
                            if store.unreadTapId == id {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .id(UUID())
                            } else {
                                Image(systemSymbol: .circleFill)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 10, height: 10)
                                    .foregroundStyle(tintColor)
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(width: 40, height: 40) // Tap area
                    }
                    
                    if closed {
                        Image(systemSymbol: .lock)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color(.Labels.secondary))
                            .padding(.trailing, 12)
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0))
        .buttonStyle(.plain)
        .frame(minHeight: 60)
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
