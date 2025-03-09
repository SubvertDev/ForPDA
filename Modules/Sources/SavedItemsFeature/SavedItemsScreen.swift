//
//  SavedItemsScreen.swift
//  APIClient
//
//  Created by Рустам Ойтов on 25.02.2025.
//

import Foundation
import SwiftUI
import ComposableArchitecture

struct SavedItemsScreen: View {
    
    let store: StoreOf<SavedItemsFeature>
    @State private var pickerSelection: SegmentModel = .favorites
    
    var body: some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
            
            VStack {
                SegmentPicker()
                List {
                    switch pickerSelection {
                    case .favorites:
//                        FavoritesScreen(store: store.scope(
//                            state: \.favorites,
//                            action: store.Action.bookmarks
//                        ))
                        Text("favorites")
                    case .bookmarks:
                        Text("bookmarks")
                    }
                }
            }
        }
    }
    @ViewBuilder
    private func SegmentPicker() -> some View {
        Picker(String(""), selection: $pickerSelection) {
            Text("Favorites")
                .tag(SegmentModel.favorites)
            Text("Bookmarks")
                .tag(SegmentModel.bookmarks)
        }
        .pickerStyle(.segmented)
    }
    
    enum SegmentModel {
        case favorites
        case bookmarks
    }
}
