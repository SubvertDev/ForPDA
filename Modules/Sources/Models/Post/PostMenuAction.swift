//
//  TopicPostContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 19.03.25.
//

public enum PostMenuAction {
    case reply(Int, String)
    case edit(Post)
    case delete(Int)
    case karma(Int)
    case report(Int)
    case changeReputation(Int, Int, String)
    case mentions(Int)
    case copyLink(Int)
}
