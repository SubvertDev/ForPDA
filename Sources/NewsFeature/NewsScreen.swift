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
                    Group {
                        ForEach(store.elements, id: \.self) { element in
                            NewsElementView(element: element)
                        }
                        Spacer()
                    }
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle(store.news.title)
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
    
    let element: NewsElement
    
    @ViewBuilder
    var body: some View {
        switch element {
        case .text(let textElement):
            Text(textElement.markdown)
                .environment(\.openURL, OpenURLAction { url in
                    print("TAP!!!") // RELEASE: Handle deeplink into 4pda
                    return .systemAction
                })
                .bold(textElement.isHeader)
                .padding(12)
            
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
                    news: NewsPreview(url: URL(string: "https://4pda.to/2024/05/12/427498/poetry_camera_prevraschaet_uvidennoe_v_stikhi/")!, title: "Poetry Camera прверащает увиденное в стихи.", description: "Test", imageUrl: URL(string: "https://4pda.to/s/pwpySNenqOcAabgmgXCz10SdH1JeFXwoq453mGv9CYgGW.jpg?v=1715094399")!, author: "", date: "", isReview: false, commentAmount: ""),
                    elements: .fullMock
                )
            ) {
                NewsFeature()
            }
        )
    }
}

extension Array where Element == NewsElement {
    static let fullMock: [NewsElement] = [
        .text(.init(text: "Nulla reprehenderit eiusmod consectetur aute voluptate et enim reprehenderit eu minim ea id commodo. Voluptate ipsum amet Lorem culpa pariatur Lorem consectetur dolor veniam officia dolore commodo. Incididunt ea ullamco nulla dolore nostrud pariatur. Sit ex non proident consequat culpa fugiat elit duis aliqua cupidatat labore nostrud officia est.")),
        .image(.init(url: URL(string: "https://4pda.to/s/Zy0hPxnqmrklKWliotRS8kVWdhGv.jpg")!, width: 200, height: 100)),
        .text(.init(text: "Esse id pariatur elit pariatur quis nisi pariatur do aliquip deserunt fugiat aliqua minim Lorem. Anim ut ea ea esse incididunt commodo qui laborum. Commodo aliqua irure culpa quis magna duis aliqua. Voluptate magna ut incididunt. Ipsum ex ex amet eu. Aute dolore deserunt proident elit incididunt occaecat nostrud labore Lorem duis.")),
        .image(.init(url: URL(string: "https://4pda.to/s/Zy0hPxnqmrklKWliotRS8kVWdhGv.jpg")!, description: "Test Description", width: 200, height: 75)),
        .text(.init(text: "Fugiat commodo minim aliquip deserunt laboris Lorem laborum magna voluptate reprehenderit. Elit irure in ut nostrud magna. Tempor consectetur deserunt quis ipsum cillum aute culpa. Consequat velit incididunt nostrud aute amet voluptate voluptate in ex sit dolore sunt voluptate eu commodo. Officia officia cupidatat mollit sunt excepteur id fugiat est sit amet nostrud culpa fugiat id ea.", isQuote: true))
    ]
}
