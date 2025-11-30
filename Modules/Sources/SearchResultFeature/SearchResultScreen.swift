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
import PageNavigationFeature

@ViewAction(for: SearchResultFeature.self)
public struct SearchResultScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<SearchResultFeature>
    
    @Environment(\.tintColor) private var tintColor
    
    @State private var navigationMinimized = false
    
    private var shouldShowNavigation: Bool {
        let isAnyFloatingNavigationEnabled = store.appSettings.floatingNavigation || store.appSettings.experimentalFloatingNavigation
        return store.pageNavigation.shouldShow && (!isLiquidGlass || !isAnyFloatingNavigationEnabled)
    }
    
    // MARK: - Init
    
    public init(store: StoreOf<SearchResultFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if !store.isLoading {
                    if !store.content.isEmpty {
                        List {
                            if shouldShowNavigation {
                                Navigation()
                            }
                            
                            ForEach(store.content) { type in
                                switch type {
                                case .post(let post):
                                    PostSection(post)
                                case .topic(let topic):
                                    TopicSection(topic)
                                case .article(let article):
                                    ArticleRow(article)
                                }
                            }
                            
                            if shouldShowNavigation {
                                Navigation()
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    } else {
                        NothingFound()
                    }
                }
            }
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text("Search", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.Background.primary))
            ._safeAreaBar(edge: .bottom) {
                if isLiquidGlass,
                   store.appSettings.floatingNavigation,
                   !store.appSettings.experimentalFloatingNavigation {
                    PageNavigation(
                        store: store.scope(state: \.pageNavigation, action: \.pageNavigation),
                        minimized: $navigationMinimized
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Post Row
    
    private func PostSection(_ post: UIContent.UIHybridPost) -> some View {
        VStack(alignment: .leading) {
            Button {
                send(.topicTapped(post.topicId, post.topicName, false))
            } label: {
                Text(verbatim: "\(post.topicName)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)
            
            PostRowView(
                state: .init(post: post.post),
                action: { _ in },
                menuAction: { _ in }
            )
            .highPriorityGesture(
                TapGesture()
                    .onEnded {
                        send(.postTapped(post.topicId, post.topicName, post.id))
                    }
            )
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
                    send(.topicTapped(topic.id, topic.name, isUnreadTapped))
                }
            )
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .listRowBackground(Color(.Background.teritary))
    }
    
    // MARK: - Article Row
    
    private func ArticleRow(_ article: ArticlePreview) -> some View {
        Button {
            send(.articleTapped(article))
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
                rowType: settingsToRow(store.appSettings.articlesListRowType),
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
    
    private func settingsToRow(_ rowType: AppSettings.ArticleListRowType) -> ArticleRowView.RowType {
        rowType == AppSettings.ArticleListRowType.normal ? ArticleRowView.RowType.normal : ArticleRowView.RowType.short
    }
    
    // MARK: - Navigation
    
    @ViewBuilder
    private func Navigation() -> some View {
        if store.pageNavigation.shouldShow {
            PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
                .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Nothing Found
    
    private func NothingFound() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .magnifyingglass)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("Nothing found", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundStyle(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text("Try entering a different query or changing your search parameters", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7)
                .padding(.horizontal, 55)
        }
    }
}

#Preview {
    NavigationStack {
        SearchResultScreen(
            store: Store(
                initialState: SearchResultFeature.State(
                    search: .mock
                ),
            ) {
                SearchResultFeature()
            }
        )
    }
}
