//
//  ArticleElementView.swift
//
//
//  Created by Ilia Lubianoi on 03.07.2024.
//

import SwiftUI
import ComposableArchitecture
import NukeUI
import SkeletonUI
import YouTubePlayerKit
import SharedUI
import Models

struct ArticleElementView: View {
    
    @Environment(\.openURL) private var openURL
    @State private var gallerySelection: Int = 0
    
    // TODO: Is it good to send store here?
    let store: StoreOf<ArticleFeature>
    let element: ArticleElement
    
    var body: some View {
        switch element {
            
            // MARK: - Text
            
        case .text(let textElement):
            HStack {
                if textElement.isQuote {
                    Rectangle()
                        .foregroundStyle(.gray.opacity(2/3))
                        .frame(width: 16)
                        .overlay(alignment: .top) {
                            Image(systemSymbol: .quoteClosing)
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.white)
                                .padding(1)
                        }
                }
                
                Text(textElement.markdown)
                    .environment(\.openURL, OpenURLAction { url in
                        store.send(.linkInTextTapped(url))
                        return .handled
                    })
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(textElement.isHeader ? .title : .body)
                    .padding(.horizontal, 12)
            }
            
            // MARK: - Image
            
        case .image(let imageElement):
            LazyImage(url: imageElement.url) { state in
                Group {
                    if let image = state.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color(.systemBackground)
                    }
                }
                .skeleton(with: state.isLoading, shape: .rectangle)
            }
            .frame(width: UIScreen.main.bounds.width,
                   height: UIScreen.main.bounds.width * imageElement.ratioHW)
            .clipped()
            
            // MARK: - Gallery
            
        case .gallery(let imageElements):
            HeightPreservingTabView {
                ForEach(imageElements, id: \.self) { imageElement in
                    LazyImage(url: imageElement.url) { state in
                        Group {
                            if let image = state.image {
                                image.resizable().scaledToFill()
                            } else {
                                Color(.systemBackground)
                            }
                        }
                        .skeleton(with: state.isLoading, shape: .rectangle)
                    }
                    .aspectRatio(imageElement.ratioWH, contentMode: .fill)
                    .frame(height: UIScreen.main.bounds.width * imageElement.ratioHW)
                    .clipped()
                }
                .padding(.bottom, 48) // Fix against index overlaying
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding(.bottom, -16)
            
            // MARK: - Video
            
        case .video(let videoElement):
            let player = YouTubePlayer(source: .video(id: videoElement.id))
            YouTubePlayerView(player) { state in
                switch state {
                    // TODO: Handle error
                case .idle, .error:
                    Color(.systemBackground)
                        .skeleton(with: true, shape: .rectangle)
                case .ready:
                    EmptyView()
                }
            }
            .frame(height: UIScreen.main.bounds.width * 0.5625)
            
            // MARK: - Gif
            
        case .gif(let gifElement):
            GifView(url: gifElement.url) // TODO: Add skeleton?
            
            // MARK: - Button
            
        case .button(let buttonElement):
            Button {
                openURL(buttonElement.url)
            } label: {
                Text(buttonElement.text)
            }
            .buttonStyle(.borderedProminent)
            
            // MARK: - Bullet List
            
        case .bulletList(let bulletListElement):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(bulletListElement.elements, id: \.self) { element in
                    HStack(spacing: 8) {
                        Circle()
                            .frame(width: 8, height: 8)
                        
                        Text(element)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            
            // MARK: - Table
            
        case .table(let tableElement):
            VStack(spacing: 0) {
                ForEach(Array(tableElement.rows.enumerated()), id: \.0) { index, row in
                    VStack(spacing: 4) {
                        Text(row.title)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(row.description)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 8)
                    
                    if index < tableElement.rows.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// TODO: Make multiple previews
#Preview {
    ArticleElementView(
        store: .init(
            initialState: ArticleFeature.State(
                articlePreview: .mock
            ),
            reducer: {
                ArticleFeature()
            }
        ),
        element: .text(.init(text: Array(repeating: "Test ", count: 30).joined(), isQuote: true))
    )
    .frame(height: 100)
}

#Preview("Bullet List") {
    ArticleElementView(
        store: .init(
            initialState: ArticleFeature.State(
                articlePreview: .mock
            ),
            reducer: {
                ArticleFeature()
            }
        ),
        element: .bulletList(
            .init(
                elements: ["First Element", "Second Element", "Third Element", "Fourth Element", "Fifth Element"]
            )
        )
    )
    .frame(height: 100)
}
