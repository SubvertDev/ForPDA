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
            
            ForEach(favorites, id: \.hashValue) { fav in
                HStack(spacing: 25) {
                    Row(title: fav.topic.name, unread: fav.topic.isUnread, notify: fav.notify) {
                        store.send(.favoriteTapped(id: fav.topic.id, name: fav.topic.name, isForum: fav.isForum))
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .buttonStyle(.plain)
                .frame(height: 60)
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
    private func Row(title: String, unread: Bool = false, notify: FavoriteInfo.Notify, action: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    // TODO: Add notify symbol.
                    // If notify - .all, and isNotifyHatUpdate == true,
                    // then display isNotifyHatUpdate symbol.
                    
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Color.Labels.primary)
                    
                    // TODO: Add last post info.
                    
                    Spacer(minLength: 8)
                    
                    if unread {
                        Circle()
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 8)
                            .padding(.trailing, 12)
                    }
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(height: 60)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .foregroundStyle(Color.Labels.teritary)
            .textCase(nil)
            .offset(x: 0)
            .padding(.bottom, 4)
    }
    
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
