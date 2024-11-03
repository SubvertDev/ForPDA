//
//  CustomContextMenuModifier.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 23.08.2024.
//

import SwiftUI

public struct PDAContextMenuModifier: ViewModifier {
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
    
    public func body(content: Content) -> some View {
        content
            .contextMenu {
                MenuButtons(
                    title: title,
                    authorName: authorName,
                    contextMenuActions: contextMenuActions
                )
            }
    }
}

public extension View {
    func pdaContextMenu(title: String, authorName: String, contextMenuActions: ContextMenuActions) -> some View {
        self.modifier(PDAContextMenuModifier(title: title, authorName: authorName, contextMenuActions: contextMenuActions))
    }
}
