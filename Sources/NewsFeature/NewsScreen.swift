//
//  NewsScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture

public struct NewsScreen: View {
    
    @Perception.Bindable public var store: StoreOf<NewsFeature>
    
    public init(store: StoreOf<NewsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            Text(store.news.info.title)
        }
    }
}

// MARK: - Preview

#Preview {
    NewsScreen(
        store: Store(
            initialState: NewsFeature.State(news: .mock)
        ) {
            NewsFeature()
        }
    )
}
