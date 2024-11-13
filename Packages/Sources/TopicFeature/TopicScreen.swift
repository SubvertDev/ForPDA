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
                        Group {
                            if store.pageNavigation.shouldShow {
                                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                            }
                            
                            VStack(spacing: 0) {
                                ForEach(Array(topic.posts.enumerated()), id: \.0) { index, post in
                                    WithPerceptionTracking {
                                        Divider()
                                        if !store.isFirstPage && index == 0 {
                                            Text("Шапка Темы")
                                                .padding(16)
                                        } else {
                                            Post(post)
                                                .padding(.bottom, 16)
                                        }
                                        Divider()
                                    }
                                }
                            }
                            
                            if store.pageNavigation.shouldShow {
                                PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
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
        VStack(spacing: 8) {
            PostHeader(post)
            PostBody(post)
        }
    }
    
    // MARK: - Post Header
    
    @ViewBuilder
    private func PostHeader(_ post: Post) -> some View {
        HStack {
            Text(post.author.name)
            
            Spacer()
            
            Text(post.createdAt.formatted())
        }
        .padding()
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
