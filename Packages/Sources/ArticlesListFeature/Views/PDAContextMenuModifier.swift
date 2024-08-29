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

public struct PDAContextMenuModifier: ViewModifier {
    public let article: ArticlePreview
    public let store: StoreOf<ArticlesListFeature>
    
    public init(article: ArticlePreview, store: StoreOf<ArticlesListFeature>) {
        self.article = article
        self.store = store
    }
    
    public func body(content: Content) -> some View {
        content
            .contextMenu {
                ContextButton(text: "Copy Link", symbol: .doc, bundle: .module) {
                    store.send(.cellMenuOpened(article, .copyLink))
                }
                ContextButton(text: "Share Link", symbol: .arrowTurnUpRight, bundle: .module) {
                    store.send(.cellMenuOpened(article, .shareLink))
                }
                ContextButton(text: "Problems with article?", symbol: .questionmarkCircle, bundle: .module) {
                    store.send(.cellMenuOpened(article, .report))
                }
            }
    }
}

public extension View {
    func pdaContextMenu(article: ArticlePreview, store: StoreOf<ArticlesListFeature>) -> some View {
        self.modifier(PDAContextMenuModifier(article: article, store: store))
    }
}
