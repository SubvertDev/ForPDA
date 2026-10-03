//
//  SearchSort.swift
//  ForPDA
//
//  Created by Xialtal on 25.11.25.
//

public enum SearchSort: String, Sendable, Equatable, Codable {
    
    case dateDescSort = "dd"
    case dateAscSort  = "da"
    case relevance    = ""
    
    var _rawValue: String {
        switch self {
        case .dateDescSort: "dateDescSort"
        case .dateAscSort:  "dateAscSort"
        case .relevance:    "relevance"
        }
    }
    
    public init(rawValue: String) {
        switch rawValue {
        case "dd": self = .dateDescSort
        case "da": self = .dateAscSort
        default: self = .relevance
        }
    }
}
