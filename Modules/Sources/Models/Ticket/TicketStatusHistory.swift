//
//  TicketStatusHistory.swift
//  ForPDA
//
//  Created by Xialtal on 10.05.26.
//

import Foundation

public struct TicketStatusHistory: Sendable, Identifiable {
    public let status: TicketStatus
    public let handlerId: Int
    public let handlerName: String
    public let changedAt: Date
    
    public var id: Int {
        return Int(changedAt.timeIntervalSince1970) | handlerId
    }
    
    public init(
        status: TicketStatus,
        handlerId: Int,
        handlerName: String,
        changedAt: Date
    ) {
        self.status = status
        self.handlerId = handlerId
        self.handlerName = handlerName
        self.changedAt = changedAt
    }
}

public extension TicketStatusHistory {
    static let mockNotProcessed = TicketStatusHistory(
        status: .notProcessed,
        handlerId: 0,
        handlerName: "",
        changedAt: Date.distantPast
    )
    
    static let mockProcessing = TicketStatusHistory(
        status: .processing,
        handlerId: 6176341,
        handlerName: "AirFlare",
        changedAt: Date.now - 6176341
    )
    
    static let mockProcessed = TicketStatusHistory(
        status: .processed,
        handlerId: 6176341,
        handlerName: "AirFlare",
        changedAt: Date.now
    )
}
