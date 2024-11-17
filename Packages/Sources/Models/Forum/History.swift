//
//  HistoryInfo.swift
//  ForPDA
//
//  Created by Xialtal on 17.11.24.
//

public struct History: Codable, Hashable, Sendable {
    public let histories: [HistoryInfo]
    public let historiesCount: Int
    
    public init(
        histories: [HistoryInfo],
        historiesCount: Int
    ) {
        self.histories = histories
        self.historiesCount = historiesCount
    }
}

public extension History {
    static let mock = History(
        histories: [
            .mockToday,
            .mockYesterday,
            .mockWeekAgo
        ],
        historiesCount: 1
    )
}
