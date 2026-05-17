//
//  ReputationVoteContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 14.05.26.
//

import Models

public enum ReputationVoteContextMenuAction {
    case report(Int)
    case modify(Int, ReputationModifyActionType)
    case goToAuthor(Int)
}
