//
//  TicketsList.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

public struct TicketsList: Sendable {
    public let tickets: [TicketSimplified]
    public let availableCount: Int
    
    public struct TicketSimplified: Sendable, Identifiable {
        public let id: Int
        public let info: TicketInfo
        
        public init(id: Int, info: TicketInfo) {
            self.id = id
            self.info = info
        }
    }
    
    public init(tickets: [TicketSimplified], availableCount: Int) {
        self.tickets = tickets
        self.availableCount = availableCount
    }
}

public extension TicketsList {
    static let mock = TicketsList(
        tickets: [
            .init(id: 0, info: .mock)
        ],
        availableCount: 1
    )
}
