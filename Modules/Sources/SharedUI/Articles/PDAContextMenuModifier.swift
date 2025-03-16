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
    
    public func body(content: Content) -> some View {
        content
            .contextMenu {
                MenuButtons(
                    title: title,
                    authorName: authorName,
                    contextMenuActions: contextMenuActions,
                    bundle: bundle
                )
            }
    }
}

public extension View {
    func pdaContextMenu(
        title: String,
        authorName: String,
        contextMenuActions: ContextMenuActions,
        bundle: Bundle
    ) -> some View {
        self.modifier(
            PDAContextMenuModifier(
                title: title,
                authorName: authorName,
                contextMenuActions: contextMenuActions,
                bundle: bundle
            )
        )
    }
}
