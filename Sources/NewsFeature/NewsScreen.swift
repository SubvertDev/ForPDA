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
                    LazyImage(url: store.news.preview.imageUrl) { state in
                        if let image = state.image { image.resizable().scaledToFill() }
                    }
                    .frame(height: UIScreen.main.bounds.width * 0.6)
                    .clipped()
                    
                    VStack {
                        Spacer()
                        
                        Text(store.news.preview.title)
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
                
                if store.isLoading {
                    Spacer()
                        .frame(height: UIScreen.main.bounds.height * 0.2)
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Loading news...")
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(store.news.elements, id: \.self) { element in
                            NewsElementView(store: store, element: element)
                                .padding(.vertical, 8)
                        }
                    }
                    Spacer()
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle(store.news.preview.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ContextButton(text: "Copy Link", symbol: .doc) {
                            store.send(.menuActionTapped(.copyLink))
                        }
                        ContextShareButton(
                            text: "Share Link",
                            symbol: .arrowTurnUpRight,
                            showShareSheet: $store.showShareSheet,
                            shareURL: store.news.url
                        ) {
                            store.send(.menuActionTapped(.shareLink))
                        }
                        ContextButton(text: "Problem with news?", symbol: .questionmarkCircle) {
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

struct NewsElementView: View {
    
    @Environment(\.openURL) private var openURL
    
    let store: StoreOf<NewsFeature>
    let element: NewsElement
    
    @ViewBuilder
    var body: some View {
        switch element {
        case .text(let textElement):
            Text(textElement.markdown)
                .environment(\.openURL, OpenURLAction { url in
                    store.send(.linkInTextTapped(url))
                    return .handled
                })
                .frame(maxWidth: .infinity, alignment: .leading)
                .bold(textElement.isHeader)
                .padding(.horizontal, 12)
            
        case .image(let imageElement):
            LazyImage(url: imageElement.url) { state in
                if let image = state.image { image.resizable().scaledToFill() }
            }
            .frame(width: UIScreen.main.bounds.width,
                   height: UIScreen.main.bounds.width * imageElement.ratioHW)
            .clipped()
            
        case .video(let videoElement): // RELEASE: URL is actually an ID
            let player = YouTubePlayer(source: .video(id: videoElement.url))
            YouTubePlayerView(player)
                .frame(height: UIScreen.main.bounds.width * 0.5625)
            
        case .gif(let gifElement):
            GifView(url: gifElement.url) // RELEASE: TEST
            
        case .button(let buttonElement):
            Button {
                openURL(buttonElement.url)
            } label: {
                Text(buttonElement.text)
            }
            .buttonStyle(.borderedProminent)
            
        case .bulletList(let bulletListElement):
            fatalError(bulletListElement.elements.first!.title)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NewsScreen(
            store: Store(
                initialState: NewsFeature.State(
                    news: News(
                        preview: .mock(),
                        elements: .fullMock
                    )
                )
            ) {
                NewsFeature()
            }
        )
    }
}
