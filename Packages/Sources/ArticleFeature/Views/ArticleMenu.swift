//
//  CustomContextMenuModifier.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

public struct ArticleMenu: View {
    public let article: ArticlePreview
    public let store: StoreOf<ArticleFeature>
    
    public init(article: ArticlePreview, store: StoreOf<ArticleFeature>) {
        self.article = article
        self.store = store
    }
    
    public var body: some View {
        Menu {
            ContextButton(text: "Copy Link", symbol: .doc, bundle: .module) {
                store.send(.menuActionTapped(.copyLink))
            }
            ContextButton(text: "Share Link", symbol: .arrowTurnUpRight, bundle: .module) {
                store.send(.menuActionTapped(.shareLink))
            }
            ContextButton(text: "Problem with article?", symbol: .questionmarkCircle, bundle: .module) {
                store.send(.menuActionTapped(.report))
            }
        } label: {
            Image(systemSymbol: .ellipsis)
        }
    }
}
