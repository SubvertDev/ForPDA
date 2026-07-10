//
//  ForumModifyType.swift
//  ForPDA
//
//  Created by Xialtal on 8.04.26.
//

import PDAPI
import Models

public enum ForumModifyType: Sendable {
    case post(PostModifyAction)
    case topic(TopicModifyAction)
}

extension ForumModifyType {
    var transfer: ForumCommand.ModifyType {
        switch self {
        case .post(let action):
            .post(action: action.transfer)
        case .topic(let action):
            .topic(action: action.transfer)
        }
    }
}

fileprivate extension PostModifyAction {
    var transfer: ForumCommand.ModifyPostAction {
        switch self {
        case .pin:     .pin
        case .hide:    .hide
        case .delete:  .delete
        case .protect: .protect
        }
    }
}

fileprivate extension TopicModifyAction {
    var transfer: ForumCommand.ModifyTopicAction {
        switch self {
        case .pin:    .pin
        case .hide:   .hide
        case .close:  .close
        case .delete: .delete
        }
    }
}
