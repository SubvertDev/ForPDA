//
//  BookmarksScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import SharedUI
import Models

public struct BookmarksScreen: View {
    
    @Perception.Bindable public var store: StoreOf<BookmarksFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<BookmarksFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                ScrollViewReader { reader in
                    WithPerceptionTracking {
                        ArticlesList()
                            .onChange(of: store.scrollToTop) { _ in
                                withAnimation { reader.scrollTo(0) }
                            }
                    }
                }
                .refreshable {
                    await store.send(.onRefresh).finish()
                }
                
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
                
                if !store.isLoading && store.articles.isEmpty {
                    EmptyBookmarks()
                }
            }
            .navigationTitle(Text("Bookmarks", bundle: .module))
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
            .task {
                store.send(.onTask)
            }
        }
    }
    
    // MARK: - Articles List
        
    @ViewBuilder
    private func ArticlesList() -> some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(store.articles, id: \.self) { article in
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
                    }
                }
            }
            
            if !store.articles.isEmpty {
                PDALoader()
                    .frame(width: 24, height: 24)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
            }
        }
        .coordinateSpace(name: "scroll")
        .background(Color(.Background.primary))
        .scrollDisabled(store.isScrollDisabled)
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
    
    // MARK: - Empty Screen
    
    @ViewBuilder
    private func EmptyBookmarks() -> some View {
        VStack(spacing: 0) {
            Image(systemSymbol: .bookmark)
                .font(.title)
                .foregroundStyle(tintColor)
                .frame(width: 48, height: 48)
                .padding(.bottom, 8)
            
            Text("No bookmarks", bundle: .module)
                .font(.title3)
                .bold()
                .foregroundColor(Color(.Labels.primary))
                .padding(.bottom, 6)
            
            Text("Tap “Add To Bookmarks” in article menu, to save it here", bundle: .module)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.horizontal, 55)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        BookmarksScreen(
            store: Store(
                initialState: BookmarksFeature.State()
            ) {
                BookmarksFeature()
            }
        )
    }
}
