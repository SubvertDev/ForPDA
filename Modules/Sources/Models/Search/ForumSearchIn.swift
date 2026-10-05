//
//  ForumSearchIn.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.25.
//

public enum ForumSearchIn: Sendable {
    
    case all
    case posts
    case titles
    
    public var rawValue: String {
        switch self {
        case .all:    "all"
        case .posts:  "pst"
        case .titles: "top"
        }
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case "top": self = .titles
        case "pst": self = .posts
        case "all": self = .all
        default: self = .all
        }
    }
}
