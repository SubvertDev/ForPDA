//
//  BookmarksScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import SharedUI
import Models

public struct BookmarksScreen: View {
    
    @Perception.Bindable public var store: StoreOf<BookmarksFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<BookmarksFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                EmptyBookmarks()
                
                Image(.tapes)
                    .resizable()
            }
            .navigationTitle(Text("Bookmarks", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(.Background.primary), for: .navigationBar)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    // MARK: - Empty Screen
    
    @ViewBuilder
    private func EmptyBookmarks() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .bookmark)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
//            Text("No bookmarks", bundle: .module)
            Text("Bookmarks will appear soon", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundColor(Color(.Labels.primary))
                .padding(.bottom, 6)
            
//            Text("Tap “Add To Bookmarks” in article menu, to save it here", bundle: .module)
            Text("They're currently in development, stay tuned for updates", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.horizontal, 55)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        BookmarksScreen(
            store: Store(
                initialState: BookmarksFeature.State()
            ) {
                BookmarksFeature()
            }
        )
    }
}
