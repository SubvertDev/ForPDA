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

public struct ArticleScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ArticleFeature>
    
    public init(store: StoreOf<ArticleFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                ZStack {
                    LazyImage(url: store.articlePreview.imageUrl) { state in
                        if let image = state.image { image.resizable().scaledToFill() }
                    }
                    .frame(height: UIScreen.main.bounds.width * 0.6)
                    .clipped()
                    
                    VStack {
                        Spacer()
                        
                        Text(store.articlePreview.title)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .minimumScaleFactor(0.75)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .shadow(color: .black.opacity(0.75), radius: 5)
                            .shadow(color: .black, radius: 10)
                    }
                    .padding()
                }
                
                if store.isLoading {
                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.2)
                    
                    VStack {
                        ModernCircularLoader()
                            .frame(width: 24, height: 24)
                        
                        Text("Loading article...", bundle: .module)
                    }
                } else if let elements = store.elements, let comments = store.article?.comments {
                    ArticleView(store: store, elements: elements, comments: comments)
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle(store.articlePreview.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // TODO: Extract and reuse context menu?
                    Menu {
                        ContextButton(text: "Copy Link", symbol: .doc, bundle: .module) {
                            store.send(.menuActionTapped(.copyLink))
                        }
                        ContextShareButton(
                            text: "Share Link",
                            symbol: .arrowTurnUpRight,
                            bundle: .module,
                            showShareSheet: $store.showShareSheet,
                            shareURL: store.articlePreview.url
                        ) {
                            store.send(.menuActionTapped(.shareLink))
                        }
                        ContextButton(text: "Problem with article?", symbol: .questionmarkCircle, bundle: .module) {
                            store.send(.menuActionTapped(.report))
                        }
                    } label: {
                        Image(systemSymbol: .ellipsis)
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

// MARK: - Preview

#Preview {
    NavigationStack {
        ArticleScreen(
            store: Store(
                initialState: ArticleFeature.State(
                    articlePreview: .mock,
                    article: .mock
                )
            ) {
                ArticleFeature()
            }
        )
    }
}
