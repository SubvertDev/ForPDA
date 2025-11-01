//
//  FavoritesRootScreen.swift
//  FavoritesRootFeature
//
//  Created by Рустам Ойтов on 02.03.2025.
//

import ComposableArchitecture
import SwiftUI
import FavoritesFeature
import BookmarksFeature
import PageNavigationFeature
import SFSafeSymbols
import SharedUI
import Models

@ViewAction(for: FavoritesRootFeature.self)
public struct FavoritesRootScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<FavoritesRootFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<FavoritesRootFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                VStack {
                    SegmentPicker()
                    
                    switch store.pickerSelection {
                    case .favorites:
                        FavoritesScreen(store: store.scope(state: \.favorites, action: \.favorites))
                        
                    case .bookmarks:
                        BookmarksScreen(store: store.scope(state: \.bookmarks, action: \.bookmarks))
                    }
                }
            }
            .animation(.default, value: store.pickerSelection)
        }
    }
    
    // MARK: - Segment Picker
    
    @ViewBuilder
    private func SegmentPicker() -> some View {
        Picker(String(""), selection: $store.pickerSelection) {
            Text("Favorites", bundle: .module)
                .tag(FavoritesRootFeature.PickerSelection.favorites)
            
            Text("Bookmarks", bundle: .module)
                .tag(FavoritesRootFeature.PickerSelection.bookmarks)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview {
    @Shared(.userSession) var userSession
    $userSession.withLock { $0 = .mock }
    
    return NavigationStack {
        FavoritesRootScreen(
            store: Store(
                initialState: FavoritesRootFeature.State(),
                reducer: {
                    FavoritesRootFeature()
                }
            )
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
    .tint(Color(.Theme.primary))
}
