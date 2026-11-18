//
//  HistoryRow.swift
//  ForPDA
//
//  Created by Xialtal on 17.11.24.
//

import Foundation
import Models

public struct HistoryRow: Hashable {
    public let seenDate: Date
    public var topics: [TopicInfo]
    
    public init(seenDate: Date, topics: [TopicInfo]) {
        self.seenDate = seenDate
        self.topics = topics
    }
}
