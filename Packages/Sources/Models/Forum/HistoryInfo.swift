//
//  History.swift
//  ForPDA
//
//  Created by Xialtal on 8.11.24.
//

import Foundation

public struct HistoryInfo: Codable, Sendable, Hashable {
    public let seenDate: Date
    public let topic: TopicInfo
    
    public init(seenDate: Date, topic: TopicInfo) {
        self.seenDate = seenDate
        self.topic = topic
    }
}

public extension HistoryInfo {
    static let mockToday = HistoryInfo(
        seenDate: Date.now,
        topic: .mockToday
    )
    
    static let mockYesterday = HistoryInfo(
        seenDate: .now.addingTimeInterval(-86400),
        topic: .mockYesterday
    )
    
    static let mockWeekAgo = HistoryInfo(
        seenDate: .now.addingTimeInterval(-86400 * 7),
        topic: .mockWeekAgo
    )
}
