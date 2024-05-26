//
//  NewsListScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

public struct NewsListScreen: View {
    
    @Perception.Bindable public var store: StoreOf<NewsListFeature>
    
    public init(store: StoreOf<NewsListFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                List {
                    ForEach(store.news) { news in
                        WithPerceptionTracking {
                            Button {
                                store.send(.newsTapped(news))
                            } label: {
                                NewsListRowView(news: news)
                                    .contextMenu { // RELEASE: Extract
                                        ContextButton(text: "Copy Link", symbol: .doc) {
                                            store.send(.cellMenuOpened(news, .copyLink))
                                        }
                                        ContextShareButton(
                                            text: "Share Link",
                                            symbol: .arrowTurnUpRight,
                                            showShareSheet: $store.showShareSheet,
                                            shareURL: news.url
                                        ) {
                                            store.send(.cellMenuOpened(news, .shareLink))
                                        }
                                        ContextButton(text: "Problem with news?", symbol: .questionmarkCircle) {
                                            store.send(.cellMenuOpened(news, .report))
                                        }
                                    }
                            }
                            .listSectionSeparator(.hidden)
                        }
                    }
                    
                    if !store.isLoading {
                        LoadMoreView()
                            .onAppear {
                                store.send(.onLoadMoreAppear)
                            }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden) // RELEASE: Find SUI alternative to estimatedRowHeight in UIKit to prevent scroll indicator jumping
                .navigationTitle("News")
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
                                .foregroundStyle(.black)
                        }
                    }
                }
                
                if store.isLoading {
                    ModernCircularLoader()
                        .frame(width: 24, height: 24)
                }
                
                if store.showVpnWarningBackground {
                    VStack {
                        Image(systemSymbol: .wifiExclamationmark)
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width * 0.25)
                        Text("Whoops! Looks like you have VPN on, try disabling it and refresh the page")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .alert($store.scope(state: \.alert, action: \.alert))
            .task {
                store.send(.onTask)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewsListScreen(
            store: Store(
                initialState: NewsListFeature.State()
            ) {
                NewsListFeature()
            } withDependencies: {
                $0.newsClient = .previewValue
            }
        )
    }
}
