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
                MenuButtons(
                    article: article,
                    shareAction: {
                        store.send(.cellMenuOpened(article, .shareLink))
                    },
                    copyAction: {
                        store.send(.cellMenuOpened(article, .copyLink))
                    },
                    openInBrowserAction: {
                        print("not implemented")
                    },
                    reportAction: {
                        store.send(.cellMenuOpened(article, .report))
                    },
                    addToBookmarksAction: {
                        print("not implemented")
                    }
                )
            }
    }
}

public extension View {
    func pdaContextMenu(article: ArticlePreview, store: StoreOf<ArticlesListFeature>) -> some View {
        self.modifier(PDAContextMenuModifier(article: article, store: store))
    }
}
