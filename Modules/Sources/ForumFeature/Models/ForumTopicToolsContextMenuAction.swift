//
//  ForumTopicToolsContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.26.
//

import Models

public enum ForumTopicToolsContextMenuAction {
    case move
    case merge
    case modify(TopicModifyAction, Bool)
    
    public enum TopicId {
        case id(Int)
        case multi(pinned: Bool)
    }
}
