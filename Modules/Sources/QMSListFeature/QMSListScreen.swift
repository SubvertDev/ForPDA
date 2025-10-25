//
//  QMSListScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import NukeUI
import Models

public struct QMSListScreen: View {
    
    @Perception.Bindable public var store: StoreOf<QMSListFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<QMSListFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let qms = store.qms {
                    List {
                        ForEach(Array(qms.users.enumerated()), id: \.0) { index, user in
                            WithPerceptionTracking {
                                if user.chats.isEmpty {
                                    UserRow(user)
                                } else {
                                    DisclosureGroup(isExpanded: $store.expandedGroups[index]) {
                                        ChatList(user.chats)
                                    } label: {
                                        UserRow(user)
                                    }
                                    .listRowBackground(Color(.Background.teritary))
                                }
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    ._contentMargins(.top, 16)
                } else {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle("QMS")
            ._toolbarTitleDisplayMode(.inline)
            .animation(.default, value: store.expandedGroups)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    // MARK: - User Row
    
    @ViewBuilder
    private func UserRow(_ user: QMSUser) -> some View {
        Button {
            store.send(.userRowTapped(user.id))
        } label: {
            HStack(spacing: 8) {
                LazyImage(url: user.avatarUrl ?? Links.defaultQMSAvatar) { state in
                    Group {
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(.avatarDefault).resizable()
                        }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .frame(width: 50, height: 50)
                
                Text(user.name)
                
                Spacer()
                
                if user.unreadCount > 0 {
                    Circle()
                        .font(.title2)
                        .foregroundStyle(tintColor)
                        .frame(width: 8)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Chat Row
    
    @ViewBuilder
    private func ChatRow(_ chat: QMSChatInfo) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                store.send(.chatRowTapped(chat.id))
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chat.name)
                        Text(chat.lastMessageDate.formatted())
                    }
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Circle()
                            .font(.title2)
                            .foregroundStyle(tintColor)
                            .frame(width: 8)
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Chat List
    
    @ViewBuilder
    private func ChatList(_ chats: [QMSChatInfo]) -> some View {
        ForEach(chats) { chat in
            ChatRow(chat)
        }
    }
}

#Preview {
    QMSListScreen(store: Store(initialState: QMSListFeature.State()) {
        QMSListFeature()
    })
}
