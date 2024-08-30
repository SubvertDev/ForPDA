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
        case let .text(element):
            text(element)
                        
        case let .image(element):
            image(element)
                        
        case let .gallery(element):
            gallery(element)
                        
        case let .video(element):
            video(element)
                        
        case let .gif(element):
            GifView(url: element.url) // TODO: Add skeleton?
                        
        case let .button(element):
            button(element)
                        
        case let .bulletList(element):
            bulletList(element)
                        
        case let .table(element):
            table(element)
            
        case let .advertisement(element):
            advertisement(element)
        }
    }
    
    // MARK: - Text
    
    @ViewBuilder
    private func text(_ element: TextElement) -> some View {
        HStack {
            if element.isQuote {
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
            
            Text(element.text.asMarkdown)
                .environment(\.openURL, OpenURLAction { url in
                    store.send(.linkInTextTapped(url))
                    return .handled
                })
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(element.isHeader ? .title : .body)
                .padding(.horizontal, 12)
        }
    }
    
    // MARK: - Image
    
    @ViewBuilder
    private func image(_ element: ImageElement) -> some View {
        LazyImage(url: element.url) { state in
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
               height: UIScreen.main.bounds.width * element.ratioHW)
        .clipped()
    }
    
    // MARK: - Gallery
    
    @ViewBuilder
    private func gallery(_ element: [ImageElement]) -> some View {
        TabView {
            ForEach(element, id: \.self) { imageElement in
                LazyImage(url: imageElement.url) { state in
                    Group {
                        if let image = state.image {
                            image.resizable()
                        } else {
                            Color(.systemBackground)
                        }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .aspectRatio(imageElement.ratioWH, contentMode: .fit)
                .clipped()
            }
            .padding(.bottom, 48) // Fix against index overlaying
        }
        .frame(height: CGFloat(element.max(by: { $0.ratioHW < $1.ratioHW})!.ratioHW) * UIScreen.main.bounds.width + 48)
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .padding(.bottom, -16)
    }
    
    // MARK: - Video
    
    @ViewBuilder
    private func video(_ element: VideoElement) -> some View {
        let player = YouTubePlayer(source: .video(id: element.id))
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
    }
    
    // MARK: - Button
    
    // TODO: Not used
    @ViewBuilder
    private func button(_ element: ButtonElement) -> some View {
        Button {
            openURL(element.url)
        } label: {
            Text(element.text)
        }
        .buttonStyle(.borderedProminent)
    }
    
    // MARK: - Bullet List
    
    @ViewBuilder
    private func bulletList(_ element: BulletListElement) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(element.elements, id: \.self) { element in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .frame(width: 4, height: 4)
                        .padding(.top, 8)
                    
                    Text(element.asMarkdown)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }
    
    // MARK: - Table
    
    @ViewBuilder
    private func table(_ element: TableElement) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(element.rows.enumerated()), id: \.0) { index, row in
                VStack(spacing: 4) {
                    Text(row.title)
                        .bold()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(row.description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 8)
                
                if index < element.rows.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Advertisement
    
    @ViewBuilder
    private func advertisement(_ element: AdvertisementElement) -> some View {
        Button {
            store.send(.linkInTextTapped(element.linkUrl))
        } label: {
            Text(element.buttonText)
                .font(.title3)
                .padding(16)
                .foregroundStyle(Color(hex: element.buttonForegroundColorHex))
                .background(Color(hex: element.buttonBackgroundColorHex))
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity)
        .padding([.horizontal, .bottom], 16)
    }
}

// MARK: - Previews

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
                elements: ["First Element", "Second Element", "Third Element", "Fourth Element", "Fifth Element Fifth Element Fifth Element Fifth Element"]
            )
        )
    )
    .frame(height: 100)
}
