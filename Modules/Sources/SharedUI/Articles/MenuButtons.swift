//
//  MenuButtons.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 13.09.2024.
//

import SwiftUI

public struct MenuButtons: View {
    
    public let title: String
    public let authorName: String
    public let contextMenuActions: ContextMenuActions
    
    public init(
        title: String,
        authorName: String,
        contextMenuActions: ContextMenuActions
    ) {
        self.title = title
        self.authorName = authorName
        self.contextMenuActions = contextMenuActions
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Section {
                Button {
                    contextMenuActions.shareAction()
                } label: {
                    Text(title)
                    Text(authorName)
                    Image(systemSymbol: .squareAndArrowUp)
                }
            }
            
            Section {
                ContextButton(text: "Copy Link", symbol: .docOnDoc, bundle: .module) {
                    contextMenuActions.copyAction()
                }
                ContextButton(text: "Open In Browser", symbol: .safari, bundle: .module) {
                    contextMenuActions.openInBrowserAction()
                }
//                ContextButton(text: "Problems with article?", symbol: .exclamationmarkBubble, bundle: .module) {
//                    contextMenuActions.reportAction()
//                }
            }
            
//            Section {
//                ContextButton(text: "Add To Bookmarks", symbol: .bookmark, bundle: .module) {
//                    contextMenuActions.addToBookmarksAction()
//                }
//            }
        }
    }
}
