//
//  ArticleView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 26.07.2024.
//

import SwiftUI
import ComposableArchitecture
import Models

struct ArticleView: View {
    
    let store: StoreOf<ArticleFeature>
    let elements: [ArticleElement]
    let comments: [Comment]
    
    // TODO: Check if scoping is more applicable here
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(elements, id: \.self) { element in
                    ArticleElementView(store: store, element: element)
                        .padding(.vertical, 10)
                }
            }
            .padding(.vertical, 14)
            
            CommentsView(store: store, comments: comments)
        }
    }
}

#Preview {
    ArticleView(
        store: .init(
            initialState: ArticleFeature.State(articlePreview: .mock),
            reducer: { ArticleFeature() }
        ),
        elements: [
            .text(TextElement(text: "Test"))
        ],
        comments: []
    )
}
