//
//  TicketContextMenuAction.swift
//  ForPDA
//
//  Created by Xialtal on 8.05.26.
//

import Models

public enum TicketContextMenuAction {
    case changeStatus(TicketStatus, Int)
    case statusHistory
    case openAuthor(Int)
    case copyLink
}
