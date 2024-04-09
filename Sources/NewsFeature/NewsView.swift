//
//  NewsView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture

// RELEASE: Remove SUI naming
public struct NewsView: View {
    
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
    NewsView(
        store: Store(
            initialState: NewsFeature.State(news: .mock)
        ) {
            NewsFeature()
        }
    )
}
