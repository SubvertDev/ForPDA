//
//  NewsScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture
import NukeUI
import SFSafeSymbols
import YouTubePlayerKit
import Models
import SharedUI

public struct NewsScreen: View {
    
    @Perception.Bindable public var store: StoreOf<NewsFeature>
    
    public init(store: StoreOf<NewsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                ZStack {
                    LazyImage(url: store.news.imageUrl) { state in
                        if let image = state.image { image.resizable().scaledToFill() }
                    }
                    .frame(height: UIScreen.main.bounds.width * 0.6)
                    .clipped()
                    
                    VStack {
                        Spacer()
                        
                        Text(store.news.title)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .minimumScaleFactor(0.75)
                            .lineLimit(2)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .shadow(color: .black.opacity(0.75), radius: 5)
                            .shadow(color: .black, radius: 10)
                    }
                    .padding()
                }
                
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.2)
                
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("Загружаем статью...")
                }
            }
            .navigationTitle(store.news.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ContextButton(text: "Скопировать ссылку", symbol: .doc) {
                            store.send(.menuActionTapped(.copyLink))
                        }
                        ContextShareButton(
                            text: "Поделиться ссылкой",
                            symbol: .arrowTurnUpRight,
                            showShareSheet: $store.showShareSheet,
                            shareURL: store.news.url
                        ) {
                            store.send(.menuActionTapped(.shareLink))
                        }
                        ContextButton(text: "Проблемы со статьей?", symbol: .questionmarkCircle) {
                            store.send(.menuActionTapped(.report))
                        }
                    } label: {
                        Image(systemSymbol: .ellipsis)
                    }
                }
            }
            .task {
                store.send(.onTask)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NewsScreen(
            store: Store(
                initialState: NewsFeature.State(news: NewsPreview(url: URL(string: "/")!, title: "Poetry Camera прверащает увиденное в стихи.", description: "Test", imageUrl: URL(string: "/")!, author: "", date: "", isReview: false, commentAmount: ""))
            ) {
                NewsFeature()
            }
        )
    }
}
