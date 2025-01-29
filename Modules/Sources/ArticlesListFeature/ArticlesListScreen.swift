//
//  ArticlesListScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models
import SFSafeSymbols

public struct ArticlesListScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ArticlesListFeature>
    
    public init(store: StoreOf<ArticlesListFeature>) {
        self.store = store
    }
        
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                ArticlesList()
                    .refreshable {
                        await store.send(.onRefresh).finish()
                    }
                
                if store.isLoading && store.articles.isEmpty {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text("Articles", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(.Background.primary), for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ToolbarButtons()
                }
            }
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .sheet(item: $store.destination.share, id: \.self) { url in
                // FIXME: Perceptible warning despite tracking closure
                WithPerceptionTracking {
                    ShareActivityView(url: url) { success in
                        store.send(.linkShared(success, url))
                    }
                    .presentationDetents([.medium])
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    // MARK: - Articles List
        
    @ViewBuilder
    private func ArticlesList() -> some View {
        List {
            ForEach(store.articles) { article in
                WithPerceptionTracking {
                    Button {
                        store.send(.articleTapped(article))
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
                            rowType: settingsToRow(store.listRowType),
                            contextMenuActions: ContextMenuActions(
                                shareAction:          { store.send(.cellMenuOpened(article, .shareLink)) },
                                copyAction:           { store.send(.cellMenuOpened(article, .copyLink)) },
                                openInBrowserAction:  { store.send(.cellMenuOpened(article, .openInBrowser)) },
                                reportAction:         { store.send(.cellMenuOpened(article, .report)) },
                                addToBookmarksAction: { store.send(.cellMenuOpened(article, .addToBookmarks)) }
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .listRowBackground(Color(.Background.primary))
                    .onAppear {
                        guard let index = store.articles.firstIndex(of: article) else { return }
                        if store.articles.count - 5 == index {
                            store.send(.loadMoreArticles)
                        }
                    }
                }
            }
            
            if !store.articles.isEmpty {
                PDALoader()
                    .frame(width: 24, height: 24)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            }
        }
        .listRowSpacing(14)
        .listStyle(.plain)
    }
    
    private func settingsToRow(_ rowType: AppSettings.ArticleListRowType) -> ArticleRowView.RowType {
        rowType == AppSettings.ArticleListRowType.normal ? ArticleRowView.RowType.normal : ArticleRowView.RowType.short
    }
    
    // MARK: - Toolbar Items
    
    @ViewBuilder
    private func ToolbarButtons() -> some View {
        Button {
            store.send(.listGridTypeButtonTapped)
        } label: {
            Image(systemSymbol: store.listRowType == .normal ? .rectangleGrid1x2 : .squareFillTextGrid1x2)
                .replaceDownUpByLayerEffect(value: true)
        }
        
        Button {
            store.send(.settingsButtonTapped)
        } label: {
            Image(systemSymbol: .gearshape)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ArticlesListScreen(
            store: Store(
                initialState: ArticlesListFeature.State()
            ) {
                ArticlesListFeature()
            } withDependencies: {
                $0.apiClient = .previewValue
            }
        )
    }
}

#Preview("Infinite loading") {
    NavigationStack {
        ArticlesListScreen(
            store: Store(
                initialState: ArticlesListFeature.State()
            ) {
                ArticlesListFeature()
            } withDependencies: {
                $0.apiClient.getArticlesList = { @Sendable _, _ in
                    try await Task.never()
                    return []
                }
            }
        )
    }
}
