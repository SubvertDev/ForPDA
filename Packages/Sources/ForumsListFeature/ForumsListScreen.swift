//
//  ForumScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import SharedUI

public struct ForumsListScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ForumsListFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<ForumsListFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()
                
                List(store.state.forums, id: \.id) { structure in
                    Section {
                        ForEach(structure.forums) { forum in
                            HStack(spacing: 25) {
                                Row(title: forum.name, unread: forum.isUnread, action: {
                                    store.send(.forumTapped(id: forum.id, name: forum.name))
                                })
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                            .buttonStyle(.plain)
                            .frame(height: 60)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    } header: {
                        Header(title: structure.title)
                    }
                    .listRowBackground(Color.Background.teritary)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Forum", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.settingsButtonTapped)
                    } label: {
                        Image(systemSymbol: .gearshape)
                    }
                }
            }
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(title: String, unread: Bool, action: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Color.Labels.primary)
                    
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
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ForumsListScreen(
            store: Store(
                initialState: ForumsListFeature.State()
            ) {
                ForumsListFeature()
            }
        )
    }
}