//
//  TicketsListRequest.swift
//  ForPDA
//
//  Created by Xialtal on 4.05.26.
//

public struct TicketsListRequest: Sendable {
    public let forId: Int
    public let offset: Int
    public let amount: Int
    public let isSortByForums: Bool
    public let isShowOnlyMine: Bool
    
    public init(
        forId: Int,
        offset: Int,
        amount: Int,
        isSortByForums: Bool,
        isShowOnlyMine: Bool
    ) {
        self.forId = forId
        self.offset = offset
        self.amount = amount
        self.isSortByForums = isSortByForums
        self.isShowOnlyMine = isShowOnlyMine
    }
}

extension TicketsListRequest {
    var transferSort: Int {
        var type = 0
        if isShowOnlyMine {
            type |= 1
        }
        if isSortByForums {
            type |= 4
        }
        return type
    }
}
