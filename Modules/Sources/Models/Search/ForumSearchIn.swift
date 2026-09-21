//
//  ForumSearchIn.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.25.
//

public enum ForumSearchIn: String, Sendable {
    case all    = "all"
    case posts  = "pst"
    case titles = "top"
    
    public init(rawValue: String) {
        switch rawValue {
        case "top": self = .titles
        case "pst": self = .posts
        default: self = .all
        }
    }
}
