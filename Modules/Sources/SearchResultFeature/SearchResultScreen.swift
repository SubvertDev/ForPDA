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
import BBBuilder

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
                            
                            ContentSection()
                            
                            if shouldShowNavigation {
                                Navigation()
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        ._inScrollContentDetector(state: $navigationMinimized)
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
            .safeAreaInset(edge: .bottom) {
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
            .onFirstAppear {
                send(.onFirstAppear)
            }
        }
    }
    
    // MARK: - Search Content Section
    
    private func ContentSection() -> some View {
        Section {
            ForEach(Array(store.content.enumerated()), id: \.element) { index, type in
                switch type {
                case .post(let post):
                    PostRow(post)
                case .topic(let topic):
                    TopicRow(index, topic)
                case .article(let article):
                    ArticleRow(article)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Post Row
    
    private func PostRow(_ post: UIContent.UIHybridPost) -> some View {
        VStack(alignment: .leading) {
            Button {
                send(.topicTapped(post.topicId, false))
            } label: {
                RichText(
                    text: makeAttributed("[b]\(post.topicName.fixBackgroundBBCode())[/b]", .subheadline)!,
                    isSelectable: false
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
            .padding(.top, 8)
            
            PostRowView(
                state: .init(post: post.post),
                action: { _ in },
                menuAction: { _ in }
            )
            .highPriorityGesture(
                TapGesture()
                    .onEnded {
                        send(.postTapped(post.topicId, post.id))
                    }
            )
        }
        .padding(.vertical, 12)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
        .listRowBackground(Color(.Background.primary))
    }
    
    // MARK: - Topic Row
    
    private func TopicRow(_ index: Int, _ topic: TopicInfo) -> some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                let radius: CGFloat = isLiquidGlass ? 24 : 10
                SharedUI.TopicRow(
                    title: .render(makeAttributed(topic.name.fixBackgroundBBCode(), .body)!),
                    date: topic.lastPost.date,
                    username: topic.lastPost.username,
                    isClosed: topic.isClosed,
                    isUnread: topic.isUnread,
                    onAction: { isUnreadTapped in
                        send(.topicTapped(topic.id, isUnreadTapped))
                    }
                )
                .padding(.leading, 16)
                .background(
                    Color(.Background.teritary)
                        .clipShape(
                            .rect(
                                topLeadingRadius: index == 0 ? radius : 0,
                                bottomLeadingRadius: index == store.contentCount - 1 ? radius : 0,
                                bottomTrailingRadius: index == store.contentCount - 1 ? radius : 0,
                                topTrailingRadius: index == 0 ? radius : 0
                            )
                        )
                )
            }
            .listSectionSeparator(.hidden)
            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color(.Background.primary))
        }
    }
    
    // MARK: - Article Row
    
    private func ArticleRow(_ article: ArticlePreview) -> some View {
        Button {
            send(.articleTapped(article))
        } label: {
            ArticleRowView(
                state: ArticleRowView.State(
                    id: article.id,
                    title: .render(makeAttributed(
                        "[b]\(article.title.fixBackgroundBBCode())[/b]",
                        store.appSettings.articlesListRowType == .short ? .callout : .title3
                    )!),
                    authorName: article.authorName,
                    imageUrl: article.imageUrl,
                    commentsAmount: article.commentsAmount,
                    date: article.date
                ),
                rowType: settingsToRow(store.appSettings.articlesListRowType),
                bundle: .module,
                isContextMenuSupported: false
            ) { _ in }
        }
        .buttonStyle(.plain)
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
        PageNavigation(store: store.scope(state: \.pageNavigation, action: \.pageNavigation))
            .listRowBackground(Color(.Background.primary))
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

extension SearchResultScreen {
    func makeAttributed(_ text: String, _ font: UIFont.TextStyle) -> NSAttributedString? {
        guard !text.isEmpty else { return nil }
        return BBRenderer(baseAttributes: [.font: UIFont.preferredFont(forTextStyle: font)])
            .render(text: text)
    }
}

// MARK: - Previews

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
