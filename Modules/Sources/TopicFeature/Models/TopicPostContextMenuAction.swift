//
//  TopicPostContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 19.03.25.
//

import Models

public enum TopicPostContextMenuAction {
    case reply(Int, String)
    case edit(Post)
    case delete(Int)
    case karma(Int, Bool)
}
