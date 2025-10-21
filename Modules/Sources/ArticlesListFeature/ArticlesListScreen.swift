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
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ArticlesListFeature>
    @State private var scrollProxy: ScrollViewProxy?
    
    // MARK: - Init
    
    public init(store: StoreOf<ArticlesListFeature>) {
        self.store = store
    }
    
    // MARK: - Body
        
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                switch store.viewState {
                case .loading:
                    PDALoader()
                        .frame(width: 24, height: 24)
                    
                case let .loaded(articles):
                    ScrollViewReader { proxy in
                        WithPerceptionTracking {
                            ArticlesList(articles: articles)
                                .refreshable {
                                    await store.send(.onRefresh).finish()
                                }
                                .onAppear {
                                    scrollProxy = proxy
                                }
                        }
                    }
                    
                case .networkError:
                    UnavailableView(
                        symbol: .exclamationmarkTriangleFill,
                        title: "Failed to load",
                        description: "Try again later",
                        actionTitle: "Try again",
                        action: {
                            store.send(.tryAgainButtonTapped)
                        },
                        bundle: .module
                    )
                }
            }
            .navigationTitle(Text("Articles", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(isLiquidGlass ? Color(.clear) : Color(.Background.primary), for: .navigationBar)
            .toolbar { Toolbar() }
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
            .onChange(of: store.shouldScrollToTop) { _ in
                withAnimation {
                    scrollProxy?.scrollTo(store.articles.first?.id)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    // MARK: - Articles List
        
    @ViewBuilder
    private func ArticlesList(articles: [ArticlePreview]) -> some View {
        List {
            ForEach(articles) { article in
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
                            bundle: .module
                        ) { action in
                            switch action {
                            case .shareLink:     store.send(.cellMenuOpened(article, .shareLink))
                            case .copyLink:      store.send(.cellMenuOpened(article, .copyLink))
                            case .openInBrowser: store.send(.cellMenuOpened(article, .openInBrowser))
                            }
                        }
                    }
                    .id(article.id)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
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
                    .listRowBackground(Color(.Background.primary))
            }
        }
        .listStyle(.plain)
    }
    
    private func settingsToRow(_ rowType: AppSettings.ArticleListRowType) -> ArticleRowView.RowType {
        rowType == AppSettings.ArticleListRowType.normal ? ArticleRowView.RowType.normal : ArticleRowView.RowType.short
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private func Toolbar() -> some ToolbarContent {
        ToolbarItem {
            Button {
                store.send(.listGridTypeButtonTapped)
            } label: {
                Image(systemSymbol: store.listRowType == .normal ? .rectangleGrid1x2 : .squareFillTextGrid1x2)
                    .replaceDownUpByLayerEffect(value: true)
            }
        }
        
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed)
        }
        
        ToolbarItem {
            Button {
                store.send(.settingsButtonTapped)
            } label: {
                Image(systemSymbol: .gearshape)
            }
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
