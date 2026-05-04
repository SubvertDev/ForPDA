//
//  TicketsList.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

public struct TicketsList: Sendable {
    public let tickets: [TicketInfo]
    public let availableCount: Int
    
    public init(tickets: [TicketInfo], availableCount: Int) {
        self.tickets = tickets
        self.availableCount = availableCount
    }
}

public extension TicketsList {
    static let mock = TicketsList(
        tickets: [.mock],
        availableCount: 1
    )
}
