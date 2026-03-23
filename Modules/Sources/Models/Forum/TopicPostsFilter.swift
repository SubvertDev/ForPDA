//
//  TopicPostsFilter.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

public enum TopicPostsFilter: Int, Sendable, Identifiable, CaseIterable {
    case all = 3
    case onlyHidden = 1
    case onlyDefault = 4
    case onlyDeleted = 2
    case exceptDeleted = 0
    
    public var id: Int {
        self.rawValue
    }
}
