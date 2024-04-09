//
//  NewsViewSUI.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import SwiftUI
import ComposableArchitecture

// RELEASE: Remove SUI naming
struct NewsViewSUI: View {
    
    @Perception.Bindable var store: StoreOf<NewsFeature>
    
    var body: some View {
        WithPerceptionTracking {
            Text(store.news.info.title)
        }
    }
}

#Preview {
    NewsViewSUI(
        store: Store(
            initialState: NewsFeature.State(news: .mock)
        ) {
            NewsFeature()
        }
    )
}
