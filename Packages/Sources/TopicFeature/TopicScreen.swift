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
                
                if let topic = store.topic, !store.isLoadingTopic {
                    List {
                        if store.pageNavigation.shouldShow {
                            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                        }
                        
                        ForEach(topic.posts) { post in
                            WithPerceptionTracking {
                                if !store.isFirstPage && post.first {
                                    Text("Шапка Темы")
                                        .padding(16)
                                } else {
                                    Post(post)
                                        .padding(.bottom, 16)
                                }
                            }
                        }
                        
                        if store.pageNavigation.shouldShow {
                            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                        }
                    }
                    .listStyle(.plain)
                } else {
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
            LazyImage(url: URL(string: post.author.avatarUrl)) { state in
                if let image = state.image { image.resizable().scaledToFill() }
            }
            .frame(width: 50, height: 50)
            .clipped()
            
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(post.author.name)
                        .font(.body)
                        .bold()
                    
                    Text("(\(post.author.reputationCount))")
                        .font(.caption)
                        .foregroundStyle(Color.Labels.secondary)
                }
                
                Spacer(minLength: 4)
                
                Text(User.Group(rawValue: post.author.groupId)!.title)
                    .font(.caption)
                    .foregroundStyle(Color(dynamicTuple: User.Group(rawValue: post.author.groupId)!.hexColor))
            }
            .padding(.vertical, 8)
            
            Spacer()
            
            Text(post.createdAt.formatted())
                .font(.caption)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.vertical, 8)
        }
        .frame(height: 50)
    }
    
    // MARK: - Post Body
    
    @ViewBuilder
    private func PostBody(_ post: Post) -> some View {
        RichText(text: parseContent(post.content))
    }
}

extension TopicScreen {
    func parseContent(_ content: String) -> NSAttributedString {
        return BBCodeParser.parse(content)!
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
