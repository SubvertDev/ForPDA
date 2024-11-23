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
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        if store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
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
        VStack(spacing: 16) {
            PostHeader(post)
            PostBody(post)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
    
    // MARK: - Post Header
    
    @ViewBuilder
    private func PostHeader(_ post: Post) -> some View {
        HStack {
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
                .frame(width: 50, height: 50)
                .clipped()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(post.author.name)
                        .font(.body)
                        .bold()
                    
                    Text(String(post.author.reputationCount))
                        .font(.caption)
                        .foregroundStyle(Color.Labels.secondary)
                }
                .padding(.top, 4)
                
                HStack(spacing: 4) {
                    Text(User.Group(rawValue: post.author.groupId)!.title)
                        .font(.caption)
                        .foregroundStyle(Color(dynamicTuple: User.Group(rawValue: post.author.groupId)!.hexColor))
                    
                    Spacer()
                    
                    Text(post.createdAt.formatted())
                        .font(.caption)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.vertical, 8)
                }
            }
            .padding(.vertical, 8)
        }
        .frame(height: 50)
    }
    
    // MARK: - Post Body
    
    @ViewBuilder
    private func PostBody(_ post: Post) -> some View {
        VStack(spacing: 8) {
            if let postIndex = store.topic?.posts.firstIndex(of: post) {
                ForEach(store.types[postIndex], id: \.self) { type in
                    TopicView(type: type, attachments: post.attachments)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TopicScreen(
            store: Store(
                initialState: TopicFeature.State(topicId: 0)
            ) {
                TopicFeature()
            }
        )
    }
}
