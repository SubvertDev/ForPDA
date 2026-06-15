//
//  TicketsListType.swift
//  ForPDA
//
//  Created by Xialtal on 8.05.26.
//

public enum TicketsListType: Sendable, Equatable {
    case list
    case topic(Int)
    case forum(Int)
}

extension TicketsListType {
    var isForumTickets: Bool {
        if case .forum = self {
            return true
        }
        return false
    }
}
