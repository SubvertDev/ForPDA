//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 03.07.2024.
//

import SwiftUI
import ComposableArchitecture
import NukeUI
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
            
        case .image(let imageElement):
            LazyImage(url: imageElement.url) { state in
                if let image = state.image { image.resizable().scaledToFill() }
            }
            .frame(width: UIScreen.main.bounds.width,
                   height: UIScreen.main.bounds.width * imageElement.ratioHW)
            .clipped()
            
        case .gallery(let imageElements):
            HeightPreservingTabView {
                ForEach(imageElements, id: \.self) { imageElement in
                    LazyImage(url: imageElement.url) { state in
                        if let image = state.image { image.resizable() }
                    }
                    .aspectRatio(imageElement.ratioWH, contentMode: .fill)
                    .clipped()
                }
                .padding(.bottom, 48) // Fix against index overlaying
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .padding(.bottom, -16)
            
        case .video(let videoElement):
            let player = YouTubePlayer(source: .video(id: videoElement.id))
            YouTubePlayerView(player)
                .frame(height: UIScreen.main.bounds.width * 0.5625)
            
        case .gif(let gifElement):
            GifView(url: gifElement.url) // TODO: TEST
            
        case .button(let buttonElement):
            Button {
                openURL(buttonElement.url)
            } label: {
                Text(buttonElement.text)
            }
            .buttonStyle(.borderedProminent)
            
        case .bulletList(let bulletListElement):
            fatalError(bulletListElement.elements.first!.title)
            
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
