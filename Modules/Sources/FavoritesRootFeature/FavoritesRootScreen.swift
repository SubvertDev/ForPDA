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
    
    public let store: StoreOf<FavoritesRootFeature>
    @State private var pickerSelection: PickerSelection = .favorites
    @Environment(\.tintColor) private var tintColor
    
    public enum PickerSelection {
        case favorites
        case bookmarks
    }
    
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
                        
                        switch pickerSelection {
                        case .favorites:
                            FavoritesScreen(store: store.scope(state: \.favorites, action: \.favorites))
                            
                        case .bookmarks:
                            BookmarksScreen(store: store.scope(state: \.bookmarks, action: \.bookmarks))
                        }
                    }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        send(.settingsButtonTapped)
                    } label: {
                        Image(systemSymbol: .gearshape)
                    }
                }
            }
            .animation(.default, value: pickerSelection)
        }
    }
    
    // MARK: - Segment Picker
    
    @ViewBuilder
    private func SegmentPicker() -> some View {
        Picker(String(""), selection: $pickerSelection) {
            Text("Favorites", bundle: .module)
                .tag(FavoritesRootScreen.PickerSelection.favorites)
            
            Text("Bookmarks", bundle: .module)
                .tag(FavoritesRootScreen.PickerSelection.bookmarks)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview {
    FavoritesRootScreen(
        store: Store(
            initialState: FavoritesRootFeature.State(),
            reducer: {
                FavoritesRootFeature()
            }
        )
    )
}
