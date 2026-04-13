//
//  ForumTopicToolsContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.26.
//

import Models

public enum ForumTopicToolsContextMenuAction {
    case move(Int)
    case modify(TopicModifyAction, Int, Bool)
}
