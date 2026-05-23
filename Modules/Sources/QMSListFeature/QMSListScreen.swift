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
                                    DisclosureGroup(isExpanded: $store.expandedGroups[index]) {
                                        ExpandedUserContent(user)
                                    } label: {
                                        UserRow(user)
                                            .contextMenu {
                                                UserContextMenu(user: user)
                                            }
                                    }
                                    .listRowBackground(Color(.Background.teritary))
                                }
                            }
                        }
                        .refreshable {
                            await send(.onRefresh).finish()
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
                        GenericView(
                            systemSymbol: .person2,
                            title: LocalizedStringResource("No chats", bundle: .module),
                            description: LocalizedStringResource("Start chatting with other 4PDA users", bundle: .module),
                            actionTitle: LocalizedStringResource("Create chat", bundle: .module)
                        ) {
                            send(.createChatButtonTapped(user: nil))
                        }
                        
                    case .error:
                        GenericView.GenericError {
                            send(.tryAgainButtonTapped)
                        }
                    }

            }
            .animation(.default, value: store.viewState)
            .navigationTitle("QMS")
            ._toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItems()
            }
            .sheet(item: $store.scope(state: \.$createChat, action: \.createChat)) { store in
                NavigationStack {
                    CreateChatScreen(store: store)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Toolbar Items
    
    @ToolbarContentBuilder
    private func ToolbarItems() -> some ToolbarContent {
        if let qms = store.qms, !qms.users.isEmpty {
            ToolbarItem {
                Button {
                    
                } label: {
                    Image(systemSymbol: .magnifyingglass)
                }
            }
        }
        
        if #available(iOS 26, *) {
            ToolbarSpacer()
        }
        
        ToolbarItem {
            Menu {
                Section {
                    ContextButton(
                        text: LocalizedStringResource("Blacklist", bundle: .module),
                        symbol: .personCropCircleBadgeXmark
                    ) {
                        
                    }
                }
                Section {
                    ContextButton(
                        text: LocalizedStringResource("Add to bookmarks", bundle: .module),
                        symbol: .bookmark
                    ) {
                        
                    }
                    
                    ContextButton(
                        text: LocalizedStringResource("Create chat", bundle: .module),
                        symbol: .plus
                    ) {
                        send(.createChatButtonTapped(user: nil))
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
            HStack(spacing: 12) {
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
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                
                Text(user.name)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.primary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color(.Background.teritary))
        .badge(user.unreadCount)
        ._badgeProminence(.increased)
    }
    
    // MARK: - User Context Menu
    
    @ViewBuilder
    private func UserContextMenu(user: QMSUser) -> some View {
        Section {
            ContextButton(
                text: LocalizedStringResource("Create chat", bundle: .module),
                symbol: .plus
            ) {
                send(.userContextMenu(.createChatButtonTapped, user))
            }
        }
         
        Section {
            ContextButton(
                text: LocalizedStringResource("User profile", bundle: .module),
                symbol: .personCropCircle
            ) {
                
            }
            
            ContextButton(
                text: LocalizedStringResource("Profile link", bundle: .module),
                symbol: .docOnDoc
            ) {
                
            }
        }
        
        Section {
            ContextButton(
                text: LocalizedStringResource("Add to blacklist", bundle: .module),
                symbol: .personCropCircleBadgeXmark,
                role: .destructive
            ) {
                    
            }
            
            ContextButton(
                text: LocalizedStringResource("Delete all chats", bundle: .module),
                symbol: .trash,
                role: .destructive
            ) {
                
            }
        }
    }
    
    // MARK: - Expanded User Content
    
    @ViewBuilder
    private func ExpandedUserContent(_ user: QMSUser) -> some View {
        ChatList(user)
        CreateChatRow(user)
    }
    
    
    // MARK: - Chat List
    
    @ViewBuilder
    private func ChatList(_ user: QMSUser) -> some View {
        ForEach(user.chats) { chat in
            ChatRow(chat: chat, user: user)
        }
    }
    
    // MARK: - Chat Row
    
    @ViewBuilder
    private func ChatRow(chat: QMSChatInfo, user: QMSUser) -> some View {
        Button {
            send(.chatRowTapped(chat.id))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.name)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.primary))
                
                Text(chat.lastMessageDate.formatted())
                    .font(.subheadline)
                    .foregroundStyle(Color(.Labels.secondary))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .listRowBackground(Color(.Background.teritary))
        .badge(chat.unreadCount)
        ._badgeProminence(.increased)
        .contextMenu {
            ChatContextMenu(chatId: chat.id, userId: user.id)
        }
    }
    
    // MARK: - Chat Context Menu
    
    @ViewBuilder
    private func ChatContextMenu(chatId: Int, userId: Int) -> some View {
        Section {
            ContextButton(
                text: LocalizedStringResource("Mark as read", bundle: .module),
                symbol: .checkmark
            ) {
                
            }
        }
        
        Section {
            ContextButton(
                text: LocalizedStringResource("Delete chat", bundle: .module),
                symbol: .trash,
                role: .destructive
            ) {
                send(.chatContextMenu(.deleteChatButtonTapped, chatId, userId))
            }
        }
    }
    
    // MARK: - Create Chat Row
    
    @ViewBuilder
    private func CreateChatRow(_ user: QMSUser) -> some View {
        Button {
            send(.createChatButtonTapped(user: user))
        } label: {
            HStack {
                Text("Create chat", bundle: .module)
                Spacer()
                Image(systemSymbol: .plus)
            }
            .font(.body)
            .tint(tintColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.borderless)
        .listRowBackground(Color(.Background.teritary))
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
        $0.qmsClient.loadChatList = { try await Task.never() }
    }
    
    return NavigationStack {
        QMSListScreen(store: store)
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

@available(iOS 17, *)
#Preview("QMS List Error") {
    @Previewable @State var store = Store(
        initialState: QMSListFeature.State(viewState: .error)
    ) {
        QMSListFeature()
    } withDependencies: {
        $0.qmsClient.loadChatList = { try await Task.never() }
    }
    
    return NavigationStack {
        QMSListScreen(store: store)
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
