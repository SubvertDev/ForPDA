//
//  SearchResultView.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.25.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: SearchResultFeature.self)
public struct SearchResultView: View {
    
    @Perception.Bindable public var store: StoreOf<SearchResultFeature>
    
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<SearchResultFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
            
            List {
                ForEach(store.response.content) { type in
                    switch type {
                    case .post(let post):
                        PostSection(post)
                    case .topic(let topic):
                        TopicSection(topic)
                    case .article(let article):
                        ArticleRow(article)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text("Search", bundle: .module))
        .background(Color(.Background.primary))
    }
    
    // MARK: - Post Row
    
    private func PostSection(_ post: SearchContent.HybridPost) -> some View {
        VStack {
            Button {
                send(.topicTapped)
            } label: {
                Text(verbatim: "\(post.topicName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)
            
            
        }
    }
    
    // MARK: - Topic Section
    
    private func TopicSection(_ topic: TopicInfo) -> some View {
        Section {
            TopicRow(
                title: topic.name,
                date: topic.lastPost.date,
                username: topic.lastPost.username,
                isClosed: topic.isClosed,
                isUnread: topic.isUnread,
                onAction: { isUnreadTapped in
                    
                }
            )
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Article Row
    
    private func ArticleRow(_ article: ArticlePreview) -> some View {
        Button {
            //send(.articleTapped(article))
        } label: {
            ArticleRowView(
                state: ArticleRowView.State(
                    id: article.id,
                    title: article.title,
                    authorName: article.authorName,
                    imageUrl: article.imageUrl,
                    commentsAmount: article.commentsAmount,
                    date: article.date
                ),
                rowType: .short, // From settings?
                bundle: .module
            ) { action in
                
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
        .listRowSeparator(.hidden)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color(.Background.primary))
    }
}

#Preview {
    NavigationStack {
        SearchResultView(
            store: Store(
                initialState: SearchResultFeature.State(
                    response: .mock
                ),
            ) {
                SearchResultFeature()
            }
        )
    }
}
