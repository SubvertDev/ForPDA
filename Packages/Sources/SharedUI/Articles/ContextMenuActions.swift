//
//  ContextMenuActions.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 14.09.2024.
//

import Foundation

public struct ContextMenuActions {
    public var shareAction: () -> Void
    public var copyAction: () -> Void
    public var openInBrowserAction: () -> Void
    public var reportAction: () -> Void
    public var addToBookmarksAction: () -> Void
    
    public init(
        shareAction: @escaping () -> Void,
        copyAction: @escaping () -> Void,
        openInBrowserAction: @escaping () -> Void,
        reportAction: @escaping () -> Void,
        addToBookmarksAction: @escaping () -> Void
    ) {
        self.shareAction = shareAction
        self.copyAction = copyAction
        self.openInBrowserAction = openInBrowserAction
        self.reportAction = reportAction
        self.addToBookmarksAction = addToBookmarksAction
    }
}
