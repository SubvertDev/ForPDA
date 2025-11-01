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
    public let bundle: Bundle
    
    public init(
        title: String,
        authorName: String,
        contextMenuActions: ContextMenuActions,
        bundle: Bundle
    ) {
        self.title = title
        self.authorName = authorName
        self.contextMenuActions = contextMenuActions
        self.bundle = bundle
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
                ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                    contextMenuActions.copyAction()
                }
                ContextButton(text: LocalizedStringResource("Open In Browser", bundle: .module), symbol: .safari) {
                    contextMenuActions.openInBrowserAction()
                }
            }
            
//            Section {
//                ContextButton(text: "Add To Bookmarks", symbol: .bookmark, bundle: .module) {
//                    contextMenuActions.addToBookmarksAction()
//                }
//            }
        }
    }
}
