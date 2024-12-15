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
    
    @Perception.Bindable public var store: StoreOf<FavoritesFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<FavoritesFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()

                if !store.isLoading {
                    List {
                        if !store.favoritesImportant.isEmpty {
                            FavoritesSection(favorites: store.favoritesImportant, important: true)
                        }
                        
                        FavoritesSection(favorites: store.favorites, important: false)
                    }
                    .scrollContentBackground(.hidden)
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
                        // TODO: Favorites display settings.
                        
                        Button {
                            store.send(.settingsButtonTapped)
                        } label: {
                            Image(systemSymbol: .gearshape)
                        }
                    }
                }
            }
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Topics
    
    @ViewBuilder
    private func FavoritesSection(favorites: [FavoriteInfo], important: Bool) -> some View {
        Section {
            if !important, store.pageNavigation.shouldShow {
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            }
            
            ForEach(favorites, id: \.hashValue) { favorite in
                Row(
                    title: favorite.topic.name,
                    lastPost: favorite.topic.lastPost,
                    closed: favorite.topic.isClosed,
                    unread: favorite.topic.isUnread,
                    notify: favorite.notify
                ) {
                    store.send(
                        .favoriteTapped(
                            id: favorite.topic.id,
                            name: favorite.topic.name,
                            isForum: favorite.isForum
                        )
                    )
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if !important, store.pageNavigation.shouldShow {
                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            }
        } header: {
            Header(title: important
                   ? LocalizedStringKey("Important")
                   : LocalizedStringKey("Topics / Forums"))
        }
        .listRowBackground(Color.Background.teritary)
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(
        title: String,
        lastPost: TopicInfo.LastPost? = nil,
        closed: Bool = false,
        unread: Bool = false,
        notify: FavoriteInfo.Notify,
        action: @escaping () -> Void = {}
    ) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        if let lastPost {
                            Text(lastPost.formattedDate, bundle: Bundle.models)
                                .font(.caption)
                                .foregroundStyle(Color.Labels.teritary)
                        }
                        
                        RichText(
                            text: AttributedString(title),
                            font: .body,
                            foregroundStyle: Color.Labels.primary
                        )
                        
                        if let lastPost {
                            HStack(spacing: 4) {
                                Image(systemSymbol: .personCircle)
                                    .font(.caption)
                                    .foregroundStyle(Color.Labels.secondary)
                                
                                RichText(
                                    text: AttributedString(lastPost.username),
                                    font: .caption,
                                    foregroundStyle: Color.Labels.secondary
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 0)

                    if unread {
                        Circle()
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 8)
                    }
                    
                    if closed {
                        Image(systemSymbol: .lock)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(Color.Labels.secondary)
                    }
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(minHeight: 60)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.subheadline)
            .foregroundStyle(Color.Labels.teritary)
            .textCase(nil)
            .offset(x: 0)
            .padding(.bottom, 4)
    }
}

// MARK: - Extensions

extension Bundle {
    static var models: Bundle? {
        return Bundle.allBundles.first(where: { $0.bundlePath.contains("Models") })
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        FavoritesScreen(
            store: Store(
                initialState: FavoritesFeature.State(favorites: [.mock])
            ) {
                FavoritesFeature()
            }
        )
    }
}
