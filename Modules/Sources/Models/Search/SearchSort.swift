//
//  SearchSort.swift
//  ForPDA
//
//  Created by Xialtal on 25.11.25.
//

public enum SearchSort: Sendable {
    case dateDescSort
    case dateAscSort
    case relevance
    
    public init(rawValue: String) {
        switch rawValue {
        case "dd": self = .dateDescSort
        case "da": self = .dateAscSort
        default: self = .relevance
        }
    }
}
