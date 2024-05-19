//
//  NewsListScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI

public struct NewsListScreen: View {
    
    @Perception.Bindable public var store: StoreOf<NewsListFeature>
    @State private var cock: Bool = false
    
    public init(store: StoreOf<NewsListFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                List(store.news) { news in
                    WithPerceptionTracking {
                        Button {
                            store.send(.newsTapped(news))
                        } label: {
                            NewsListRowView(news: news)
                                .contextMenu {
                                    ContextButton(text: "Скопировать ссылку", symbol: .doc) {
                                        store.send(.cellMenuOpened(news, .copyLink))
                                    }
                                    ContextShareButton(
                                        text: "Поделиться ссылкой",
                                        symbol: .arrowTurnUpRight,
                                        showShareSheet: $store.showShareSheet,
                                        shareURL: news.url
                                    ) {
                                        store.send(.cellMenuOpened(news, .shareLink))
                                    }
                                    ContextButton(text: "Проблемы со статьей?", symbol: .questionmarkCircle) {
                                        store.send(.cellMenuOpened(news, .report))
                                    }
                                }
                        }
                        .listSectionSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden) // RELEASE: Find SUI alternative to estimatedRowHeight in UIKit to prevent scroll indicator jumping
                .navigationTitle("Новости")
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
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                }
                
                if store.showVpnWarningBackground {
                    VStack {
                        Image(systemSymbol: .wifiExclamationmark)
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.main.bounds.width * 0.25)
                        Text("Упс! Похоже у вас включен ВПН, отключите его и попробуйте перезагрузить страницу")
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
