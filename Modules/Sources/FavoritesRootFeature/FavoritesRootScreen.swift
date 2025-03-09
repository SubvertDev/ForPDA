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

public struct FavoritesRootScreen: View {
    
    public enum PickerSelection {
        case favorites
        case bookmarks
    }
    
    public let store: StoreOf<FavoritesRootFeature>
    @State private var pickerSelection: PickerSelection = .favorites
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<FavoritesRootFeature>) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
                VStack {
                    SegmentPicker(selection: $pickerSelection)
                    
                    switch pickerSelection {
                    case .favorites:
                        FavoritesScreen(store: store.scope(state: \.favorites, action: \.favorites))
                        
                    case .bookmarks:
                        BookmarksScreen(store: store.scope(state: \.bookmarks, action: \.bookmarks))
                    }
                }
        }
        .onAppear {
            store.send(.favorites(.onAppear))
        }
    }
}

private struct SegmentPicker: View {
    @Binding var selection: FavoritesRootScreen.PickerSelection
    
    var body: some View {
        Picker("", selection: $selection) {
            Text("Favorites")
                .tag(FavoritesRootScreen.PickerSelection.favorites)
            
            Text("Bookmarks")
                .tag(FavoritesRootScreen.PickerSelection.bookmarks)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }
}

#Preview {
    FavoritesRootScreen(store: Store(
        initialState: FavoritesRootFeature.State(
            favorites: FavoritesFeature.State(),
            bookmarks: BookmarksFeature.State()),
        reducer: { FavoritesRootFeature() }))
}
