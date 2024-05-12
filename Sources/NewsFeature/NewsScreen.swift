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
                            .font(.title2)
                            .fontWeight(.semibold)
                            .shadow(color: .black, radius: 5)
                            .shadow(color: .black, radius: 10)
                    }
                    .padding()
                }
                
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.2)
                
                VStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(2)
                        .padding()
                    
                    Text("Загружаем статью...")
                }
            }
            .navigationTitle(store.news.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        MenuButton(title: "Скопировать ссылку", symbol: .doc) {
                            
                        }
                        MenuButton(title: "Поделиться ссылкой", symbol: .arrowTurnUpRight) {
                            
                        }
                        MenuButton(title: "Проблемы со статьей", symbol: .questionmarkCircle) {
                            
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

struct MenuButton: View {
    
    let title: String
    let symbol: SFSymbol
    var action: (() -> Void)?
    
    var body: some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(title)
                Image(systemSymbol: symbol)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NewsScreen(
            store: Store(
                initialState: NewsFeature.State(news: .mock)
            ) {
                NewsFeature()
            }
        )
    }
}
