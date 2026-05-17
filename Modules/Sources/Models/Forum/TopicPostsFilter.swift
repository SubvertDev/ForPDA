//
//  TopicPostsFilter.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

public enum TopicPostsFilter: Int, Sendable, Codable, Hashable, Identifiable, CaseIterable {
    case all = 3
    case onlyHidden = 1
    case onlyDefault = 4
    case onlyDeleted = 2
    case exceptDeleted = 0
    
    public var id: Int {
        self.rawValue
    }
    
    public init?(rawValue: String?) {
        switch rawValue {
        case "all-posts":
            self = .all
        case "invisible-posts":
            self = .onlyHidden
        case "regular-posts":
            self = .onlyDefault
        case "deleted-posts":
            self = .onlyDeleted
        default: return nil
        }
    }
    
    public var modfilter: String? {
        switch self {
        case .all:         "all-posts"
        case .onlyHidden:  "invisible-posts"
        case .onlyDefault: "regular-posts"
        case .onlyDeleted: "deleted-posts"
        case .exceptDeleted: nil
        }
    }
}
