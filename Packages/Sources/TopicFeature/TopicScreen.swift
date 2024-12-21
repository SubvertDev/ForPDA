//
//  ForumPageScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import SwiftUI
import ComposableArchitecture
import PageNavigationFeature
import SFSafeSymbols
import SharedUI
import NukeUI
import Models
import ParsingClient

public struct TopicScreen: View {
    
    @Perception.Bindable public var store: StoreOf<TopicFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<TopicFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()
                
                if let topic = store.topic {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            Navigation()
                            
                            if !store.isLoadingTopic {
                                PostList(topic: topic)
                                
                                Navigation()
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .overlay {
                if store.topic == nil || store.isLoadingTopic {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text(store.topic?.name ?? "Загружаем..."))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                OptionsMenu()
            }
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Options Menu
    
    @ViewBuilder
    private func OptionsMenu() -> some View {
        Menu {
            ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
                store.send(.contextMenu(.copyLink))
            }
            ContextButton(text: "Open In Browser", symbol: .safari, bundle: .module) {
                store.send(.contextMenu(.openInBrowser))
            }
            
            if let topic = store.topic {
                Section {
                    ContextButton(
                        text: topic.isFavorite ? "Remove from favorites" : "Add to favorites",
                        symbol: topic.isFavorite ? .starFill : .star,
                        bundle: .module
                    ) {
                        store.send(.contextMenu(.setFavorite))
                    }
                }
            }
        } label: {
            Image(systemSymbol: .ellipsisCircle)
        }
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        if store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Post List
    
    @ViewBuilder
    private func PostList(topic: Topic) -> some View {
        ForEach(topic.posts) { post in
            WithPerceptionTracking {
                VStack(spacing: 0) {
                    if !store.isFirstPage && topic.posts.first == post {
                        Text("Шапка Темы")
                            .padding(16)
                    } else {
                        Post(post)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                    
                    Rectangle()
                        .foregroundStyle(Color.Separator.post)
                        .frame(height: 10)
                }
            }
        }
    }
    
    // MARK: - Post
    
    @ViewBuilder
    private func Post(_ post: Post) -> some View {
        VStack(spacing: 8) {
            PostHeader(post)
            PostBody(post)
            if let lastEdit = post.lastEdit {
                PostFooter(lastEdit)
            }
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - Post Header
    
    @ViewBuilder
    private func PostHeader(_ post: Post) -> some View {
        HStack(spacing: 8) {
            Button {
                store.send(.userAvatarTapped(userId: post.author.id))
            } label: {
                LazyImage(url: URL(string: post.author.avatarUrl)) { state in
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Image.avatarDefault.resizable().scaledToFill()
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Text(post.author.name)
                        .font(.subheadline)
                        .bold()
                        .foregroundStyle(Color.Labels.primary)
                        .lineLimit(1)
                    
                    Text(String(post.author.reputationCount))
                        .font(.caption)
                        .foregroundStyle(Color.Labels.secondary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .foregroundStyle(Color.Background.teritary)
                        )
                    
                    Spacer()
                    
                    if post.karma != 0 {
                        Text(String(post.karma))
                            .font(.caption)
                            .foregroundStyle(Color.Labels.primary)
                    }
                }
                
                HStack(spacing: 8) {
                    Text(User.Group(rawValue: post.author.groupId)!.title)
                        .font(.caption)
                        .foregroundStyle(Color.Labels.teritary)
                    
                    Spacer()
                    
                    Text(post.createdAt.formatted())
                        .font(.caption)
                        .foregroundStyle(Color.Labels.quaternary)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
    
    // MARK: - Post Body
    
    @ViewBuilder
    private func PostBody(_ post: Post) -> some View {
        VStack(spacing: 8) {
            if let postIndex = store.topic?.posts.firstIndex(of: post) {
                if store.types.count - 1 >= postIndex {
                    ForEach(store.types[postIndex], id: \.self) { type in
                        TopicView(type: type, attachments: post.attachments) { url in
                            store.send(.urlTapped(url))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Post Footer
    
    @ViewBuilder
    private func PostFooter(_ lastEdit: Post.LastEdit) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Отредактировал: \(lastEdit.username) • \(lastEdit.date.formatted())")
            if !lastEdit.reason.isEmpty {
                Text("Причина: \(lastEdit.reason)")
            }
        }
        .font(.caption2)
        .foregroundStyle(Color.Labels.teritary)
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview {
    TopicScreen(
        store: Store(
            initialState: TopicFeature.State(topicId: 0)
        ) {
            TopicFeature()
        } withDependencies: {
            $0.apiClient.getTopic = { @Sendable _, _, _ in
                return .mock
            }
        }
    )
}
