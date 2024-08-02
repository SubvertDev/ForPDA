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

public struct ArticlesListScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ArticlesListFeature>
    
    public init(store: StoreOf<ArticlesListFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                List {
                    ForEach(store.articles, id: \.self) { article in
                        WithPerceptionTracking {
                            Button {
                                store.send(.articleTapped(article))
                            } label: {
                                ArticleRowView(article: article)
                                // TODO: Extract context menu
                                    .contextMenu {
                                        ContextButton(text: "Copy Link", symbol: .doc, bundle: .module) {
                                            store.send(.cellMenuOpened(article, .copyLink))
                                        }
                                        ContextShareButton(
                                            text: "Share Link",
                                            symbol: .arrowTurnUpRight,
                                            bundle: .module,
                                            showShareSheet: $store.showShareSheet,
                                            shareURL: article.url
                                        ) {
                                            store.send(.cellMenuOpened(article, .shareLink))
                                        }
                                        ContextButton(text: "Problems with article?", symbol: .questionmarkCircle, bundle: .module) {
                                            store.send(.cellMenuOpened(article, .report))
                                        }
                                    }
                            }
                            .listSectionSeparator(.hidden)
                        }
                    }
                    
                    if !store.isLoading && !store.articles.isEmpty {
                        LoadMoreView()
                            .onAppear {
                                store.send(.onLoadMoreAppear)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden) // RELEASE: Find SUI alternative to estimatedRowHeight in UIKit to prevent scroll indicator jumping
                .navigationTitle(Text("Articles", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .refreshable {
                    await store.send(.onRefresh).finish()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            store.send(.menuTapped)
                        } label: {
                            Image(systemSymbol: .listDash)
                                .foregroundStyle(Color(.label))
                        }
                    }
                }
                
                if store.isLoading {
                    ModernCircularLoader()
                        .frame(width: 24, height: 24)
                }
                
                // TODO: Redo as generic error
//                if store.showVpnWarningBackground {
//                    VStack {
//                        Image(systemSymbol: .wifiExclamationmark)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: UIScreen.main.bounds.width * 0.25)
//                        Text("Whoops! Looks like you have VPN on, try disabling it and refresh the page")
//                            .multilineTextAlignment(.center)
//                            .padding()
//                    }
//                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .onFirstAppear {
                store.send(.onFirstAppear)
            }
        }
    }
}

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
