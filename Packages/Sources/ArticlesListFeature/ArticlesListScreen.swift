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
                Color.Background.primary
                    .ignoresSafeArea()
                
                ArticlesList()
                    .navigationTitle(Text("Articles", bundle: .module))
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            ToolbarButtons()
                        }
                    }
                    .toolbarBackground(Color.Background.primary, for: .navigationBar)
                    .refreshable {
                        await store.send(.onRefresh).finish()
                    }
                
                if store.isLoading {
                    ModernCircularLoader()
                        .frame(width: 24, height: 24)
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
    
    // MARK: Articles List
    
    @ViewBuilder
    private func ArticlesList() -> some View {
        List {
            ForEach(store.articles, id: \.self) { article in
                WithPerceptionTracking {
                    Button {
                        store.send(.articleTapped(article))
                    } label: {
                        ArticleRowView(article: article, store: store, isShort: store.listGridTypeShort)
                            .onAppear {
                                store.send(.onArticleAppear(article))
                            }
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.Background.primary)
                    .listRowInsets(EdgeInsets(top: 7, leading: 16, bottom: 7, trailing: 16))
                }
            }
        }
        .background(Color.Background.primary)
        .listStyle(.plain)
        .scrollDisabled(store.isScrollDisabled)
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Toolbar Items
    
    @ViewBuilder
    private func ToolbarButtons() -> some View {
        Button {
            store.send(.listGridTypeButtonTapped)
        } label: {
            Image(systemSymbol: store.listGridTypeShort ? .rectangleGrid1x2 : .squareFillTextGrid1x2)
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
