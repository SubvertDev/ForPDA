//
//  TicketsListSort.swift
//  ForPDA
//
//  Created by Xialtal on 4.05.26.
//

public struct TicketsListSort: OptionSet, Sendable {
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let onlyMy   = TicketsListSort(rawValue: 1 << 0)
    public static let byForums = TicketsListSort(rawValue: 1 << 2)
}
