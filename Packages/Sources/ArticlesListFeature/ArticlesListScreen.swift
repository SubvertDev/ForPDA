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
    @State private var scrollViewContentHeight: CGFloat = 0
    
    public init(store: StoreOf<ArticlesListFeature>) {
        self.store = store
    }
        
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
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
                
                if store.isLoading && store.articles.isEmpty {
                    ModernCircularLoader()
                        .frame(width: 24, height: 24)
                }
            }
            .navigationTitle(Text("Articles", bundle: .module))
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.Background.primary, for: .navigationBar)
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
            .onFirstAppear {
                store.send(.onFirstAppear)
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
                                article: article,
                                rowType: store.listRowType,
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
            .modifier(ScrollViewOffsetObserver(store: store, scrollViewContentHeight: $scrollViewContentHeight))
            
            if !store.articles.isEmpty {
                ModernCircularLoader()
                    .frame(width: 24, height: 24)
                    .padding(.top, 14)
                    .padding(.bottom, 20)
            }
        }
        .coordinateSpace(name: "scroll")
        .background(Color.Background.primary)
        .scrollDisabled(store.isScrollDisabled)
    }
    
    // MARK: - Scroll View Offset Observer
    
    struct ScrollViewOffsetObserver: ViewModifier {
        
        let store: StoreOf<ArticlesListFeature>
        @Binding var scrollViewContentHeight: CGFloat
        
        func body(content: Content) -> some View {
            content
                .background(GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).origin)
                        .onChange(of: store.articles) { _ in
                            scrollViewContentHeight = geometry.size.height
                        }
                })
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    guard scrollViewContentHeight != 0 else { return }
                    if scrollViewContentHeight - 350 * 3 < abs(value.y) { // ~ 3 articles
                        guard !store.isLoading else { return } // Preventing actions overload
                        store.send(.scrolledToNearEnd)
                    }
                }
        }
        
        struct ScrollOffsetPreferenceKey: PreferenceKey {
            nonisolated(unsafe) static var defaultValue: CGPoint = .zero
            static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {}
        }
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
