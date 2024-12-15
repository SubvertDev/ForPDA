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
                
                if !store.forums.isEmpty {
                    List(store.forums, id: \.id) { forumRow in
                        Section {
                            ForEach(forumRow.forums) { forum in
                                HStack(spacing: 25) {
                                    Row(title: forum.name, unread: forum.isUnread) {
                                        store.send(.forumTapped(id: forum.id, name: forum.name))
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                                .buttonStyle(.plain)
                                .frame(height: 60)
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        } header: {
                            Header(title: forumRow.title)
                        }
                        .listRowBackground(Color.Background.teritary)
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
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
    private func Row(title: String, unread: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Color.Labels.primary)
                    
                    Spacer(minLength: 0)
                    
                    if unread {
                        Image(systemSymbol: .circleFill)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(tintColor)
                    }
                }
                .contentShape(Rectangle())
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
            .offset(x: -16)
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
