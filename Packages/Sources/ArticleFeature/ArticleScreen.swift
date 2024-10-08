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
import SkeletonUI

public struct ArticleScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ArticleFeature>
    
    public init(store: StoreOf<ArticleFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ArticleScrollView()
                .navigationTitle(store.articlePreview.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ArticleMenu(article: store.articlePreview, store: store)
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
    
    // MARK: - Scroll View
    
    @ViewBuilder
    private func ArticleScrollView() -> some View {
        ScrollView(.vertical) {
            ArticleHeader()
            
            if store.isLoading {
                ArticleLoader()
            } else if let elements = store.elements, let comments = store.article?.comments {
                ArticleView(store: store, elements: elements, comments: comments)
            }
        }
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Article Header
    
    @ViewBuilder
    private func ArticleHeader() -> some View {
        ZStack {
            LazyImage(url: store.articlePreview.imageUrl) { state in
                Group {
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.systemBackground)
                    }
                }
                .skeleton(with: state.isLoading, shape: .rectangle)
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
    }
    
    // MARK: - Article Loader
    
    @ViewBuilder
    private func ArticleLoader() -> some View {
        Spacer()
            .frame(height: UIScreen.main.bounds.height * 0.2)
        
        VStack {
            ModernCircularLoader()
                .frame(width: 24, height: 24)
            
            Text("Loading article...", bundle: .module)
        }
    }
}

// MARK: - Previews

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
