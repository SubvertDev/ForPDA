//
//  MenuButtons.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 13.09.2024.
//

import SwiftUI
import SharedUI
import Models

public struct MenuButtons: View {
    
    public let article: ArticlePreview
    public let shareAction: () -> Void
    public let copyAction: () -> Void
    public let openInBrowserAction: () -> Void
    public let reportAction: () -> Void
    public let addToBookmarksAction: () -> Void
    
    public init(
        article: ArticlePreview,
        shareAction: @escaping () -> Void,
        copyAction: @escaping () -> Void,
        openInBrowserAction: @escaping () -> Void,
        reportAction: @escaping () -> Void,
        addToBookmarksAction: @escaping () -> Void
    ) {
        self.article = article
        self.shareAction = shareAction
        self.copyAction = copyAction
        self.openInBrowserAction = openInBrowserAction
        self.reportAction = reportAction
        self.addToBookmarksAction = addToBookmarksAction
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Section {
                Button {
                    shareAction()
                } label: {
                    Text(article.title)
                    Text(article.authorName)
                    Image(systemSymbol: .squareAndArrowUp)
                }
            }
            
            Section {
                ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
                    copyAction()
                }
                ContextButton(text: "Open In Browser", symbol: .safari, bundle: .module) {
                    openInBrowserAction()
                }
                ContextButton(text: "Problems with article?", symbol: .exclamationmarkBubble, bundle: .module) {
                    reportAction()
                }
            }
            
            Section {
                ContextButton(text: "Add To Bookmarks", symbol: .bookmark, bundle: .module) {
                    addToBookmarksAction()
                }
            }
        }
    }
}
