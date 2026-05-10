//
//  TicketContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 8.05.26.
//

import Models

public enum TicketContextMenuAction {
    case changeStatus(TicketStatus)
    case statusHistory
    case sendComment
    case openAuthor(Int)
    case copyLink
}
