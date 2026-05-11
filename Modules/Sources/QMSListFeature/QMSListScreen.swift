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

@ViewAction(for: QMSListFeature.self)
public struct QMSListScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<QMSListFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<QMSListFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                    switch store.viewState {
                    case let .loaded(qms):
                        QMSList {
                            ForEach(Array(qms.users.enumerated()), id: \.1) { index, user in
                                WithPerceptionTracking {
                                    if user.chats.isEmpty {
                                        UserRow(user)
                                            .listRowBackground(Color(.Background.teritary))
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
                        
                    case .loading:
                        QMSList {
                            ForEach(0..<8) { _ in
                                UserRow(.placeholder)
                                    .listRowBackground(Color(.Background.teritary))
                                    .redacted(if: true)
                            }
                        }
                        
                    case .empty:
                        EmptyList()
                        
                    case .error:
                        Text(verbatim: "Error")
                    }

            }
            .toolbar {
                ToolbarItems()
            }
            .navigationTitle("QMS")
            ._toolbarTitleDisplayMode(.inline)
            .animation(.default, value: store.expandedGroups)
            .animation(.default, value: store.viewState)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Toolbar Items
    
    @ToolbarContentBuilder
    private func ToolbarItems() -> some ToolbarContent {
        ToolbarItem {
            Button {
                
            } label: {
                Image(systemSymbol: .magnifyingglass)
            }
        }
        
        if #available(iOS 26, *) {
            ToolbarSpacer()
        }
        
        ToolbarItem {
            Menu {
                Section {
                    Button {
                        
                    } label: {
                        Label {
                            Text("Blacklist", bundle: .module)
                        } icon: {
                            Image(systemSymbol: .personCropCircleBadgeXmark)
                        }
                    }
                }
                Section {
                    Button {
                        
                    } label: {
                        Label {
                            Text("Add to bookmarks", bundle: .module)
                        } icon: {
                            Image(systemSymbol: .bookmark)
                        }
                    }
                    
                    Button {
                        
                    } label: {
                        Label {
                            Text("Create chat", bundle: .module)
                        } icon: {
                            Image(systemSymbol: .plus)
                        }
                    }
                }
            } label: {
                Image(systemSymbol: .ellipsis)
            }
        }
    }
    
    // MARK: - QMS List
    
    private func QMSList<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        List {
            content()
        }
        .scrollContentBackground(.hidden)
        ._contentMargins(.top, 16)
    }
    
    // MARK: - User Row
    
    @ViewBuilder
    private func UserRow(_ user: QMSUser) -> some View {
        Button {
            if case .loaded = store.viewState {
                send(.userRowTapped(user.id))
            }
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
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color(.Background.teritary))
        .badge(user.unreadCount)
        ._badgeProminence(.increased)
    }
    
    // MARK: - Chat Row
    
    @ViewBuilder
    private func ChatRow(_ chat: QMSChatInfo) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                send(.chatRowTapped(chat.id))
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.name)
                    Text(chat.lastMessageDate.formatted())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color(.Background.teritary))
        .badge(chat.unreadCount)
        ._badgeProminence(.increased)
    }
    
    // MARK: - Chat List
    
    @ViewBuilder
    private func ChatList(_ chats: [QMSChatInfo]) -> some View {
        ForEach(chats) { chat in
            ChatRow(chat)
        }
    }
    
    // MARK: - Empty List
    
    @ViewBuilder
    private func EmptyList() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .person2)
                .font(.title)
                .foregroundStyle(tintColor)
                .padding(.bottom, 8)
            
            Text("No chats", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text("Start chatting with other 4PDA users", bundle: .module)
                .font(.footnote)
                .foregroundStyle(Color(.Labels.teritary))
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
            
            Button {
                send(.createChatButtonTapped)
            } label: {
                Label {
                    Text("Create chat", bundle: .module)
                        .font(.body)
                        .foregroundStyle(tintColor)
                } icon: {
                    Image(systemSymbol: .plus)
                        .font(.body)
                        .foregroundStyle(tintColor)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(tintColor.opacity(0.12))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview("QMS List") {
    @Previewable @State var store = Store(
        initialState: QMSListFeature.State()
    ) {
        QMSListFeature()
    }
    
    return NavigationStack {
        QMSListScreen(store: store)
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

@available(iOS 17, *)
#Preview("QMS List Empty") {
    @Previewable @State var store = Store(
        initialState: QMSListFeature.State(viewState: .empty)
    ) {
        QMSListFeature()
    } withDependencies: {
        $0.qmsClient.loadQMSList = { try await Task.never() }
    }
    
    return NavigationStack {
        QMSListScreen(store: store)
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
