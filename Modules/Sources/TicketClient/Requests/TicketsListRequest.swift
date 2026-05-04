//
//  TicketsListRequest.swift
//  ForPDA
//
//  Created by Xialtal on 4.05.26.
//

public struct TicketsListRequest: Sendable {
    public let forId: Int
    public let sort: TicketsListSort
    public let offset: Int
    public let amount: Int
    
    public init(
        forId: Int,
        sort: TicketsListSort,
        offset: Int,
        amount: Int
    ) {
        self.forId = forId
        self.sort = sort
        self.offset = offset
        self.amount = amount
    }
}
