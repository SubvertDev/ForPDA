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
    
    public init(rawValue: String) {
        switch rawValue {
        case "top": self = .titles
        case "pst": self = .posts
        default: self = .all
        }
    }
}
