//
//  ForumPageScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 07.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import SharedUI
import Models
import RichTextKit
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
                    List {
                        Group {
                            PageNavigation()
                            
                            VStack(spacing: 0) {
                                ForEach(Array(topic.posts.enumerated()), id: \.0) { index, post in
                                    WithPerceptionTracking {
                                        Divider()
                                        if store.currentPage != 1 && index == 0 {
                                            Text("Шапка Темы")
                                        } else {
                                            Post(post)
                                                .padding(.bottom, 16)
                                        }
                                        Divider()
                                    }
                                }
                            }
                            
                            PageNavigation()
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                } else {
                    ProgressView().id(UUID())
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
    private func PageNavigation() -> some View {
        HStack(spacing: 16) {
            Button {
                store.send(.pageNavigationTapped(.first))
            } label: {
                NavigationArrow(symbol: .arrowLeftToLine)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Button {
                store.send(.pageNavigationTapped(.previous))
            } label: {
                NavigationArrow(symbol: .arrowLeft)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage == 1)
            
            Text("\(store.currentPage)/\(store.totalPages)")
            
            Button {
                store.send(.pageNavigationTapped(.next))
            } label: {
                NavigationArrow(symbol: .arrowRight)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
            
            Button {
                store.send(.pageNavigationTapped(.last))
            } label: {
                NavigationArrow(symbol: .arrowRightToLine)
            }
            .buttonStyle(.plain)
            .disabled(store.currentPage + 1 > store.totalPages)
        }
        .frame(maxWidth: .infinity, maxHeight: 32)
    }
    
    // MARK: - Navigation Arrow
    
    @ViewBuilder
    private func NavigationArrow(symbol: SFSymbol) -> some View {
        Image(systemSymbol: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
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
        RichTextEditor(text: .constant(parseContent(post.content)), context: .init()) {
            ($0 as? UITextView)?.backgroundColor = .clear
            ($0 as? UITextView)?.isEditable = false
            ($0 as? UITextView)?.isScrollEnabled = false
        }
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
