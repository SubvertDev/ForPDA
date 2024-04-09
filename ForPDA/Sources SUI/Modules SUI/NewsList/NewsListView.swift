//
//  NewsListView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture

struct NewsListView: View {
    
    @Perception.Bindable var store: StoreOf<NewsListFeature>
    
    var body: some View {
        WithPerceptionTracking {
            ZStack {
                List(store.news) { news in
                    NavigationLink(state: AppFeature.Path.State.news(NewsFeature.State(news: news))) {
                        NewsListCellView(news: news)
                    }
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 12, trailing: 0)) // Navigation Link Padding Fix
                    .listSectionSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden) // FIX: Find SUI alternative to estimatedRowHeight in UIKit to prevent scroll indicator jumping
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
                }
                
                if store.showVpnWarningBackground {
                    VStack {
                        Image(systemSymbol: .wifiExclamationmark)
                            .resizable()
                            .scaledToFit()
                            .frame(width: UIScreen.width * 0.25)
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
    NewsListView(
        store: Store(
            initialState: NewsListFeature.State()
        ) {
            NewsListFeature()
                ._printChanges()
        }
    )
}
