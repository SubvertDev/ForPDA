//
//  SearchRequest.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 18.08.2025.
//

import PDAPI
import Models

public struct SearchRequest: Sendable, Equatable {
    
    public let on: SearchOn
    public let authorId: Int?
    public let text: String
    public let sort: SearchSort
    public let offset: Int
    
    public enum SearchOn: Sendable, Equatable {
        case site
        case forum(id: Int?, sIn: ForumSearchIn, asTopics: Bool = false)
        case topic(id: Int)
    }
    
    public enum ForumSearchIn : Sendable {
        case all
        case posts
        case titles
    }
    
    public enum SearchSort: Sendable {
        case dateDescSort
        case dateAscSort
        case relevance
    }
    
    public init(
        on: SearchOn,
        authorId: Int?,
        text: String,
        sort: SearchSort,
        offset: Int
    ) {
        self.on = on
        self.authorId = authorId
        self.text = text
        self.sort = sort
        self.offset = offset
    }
}

extension SearchRequest.SearchOn {
    func toPDAPISearchOn() -> SearchCommand.SearchOn {
        switch self {
        case .site:
            return .site
        case let .forum(id: id, sIn: sIn, asTopics: asTopics):
            return .forum(id: id, sIn: sIn.toPDAPIForumSearchIn(), asTopics: asTopics)
        case let .topic(id: id):
            return .topic(id: id)
        }
    }
}

extension SearchRequest.ForumSearchIn {
    func toPDAPIForumSearchIn() -> SearchCommand.ForumSearchIn {
        switch self {
        case .all:
            return .all
        case .posts:
            return .posts
        case .titles:
            return .titles
        }
    }
}

extension SearchRequest.SearchSort {
    func toPDAPISearchSort() -> SearchCommand.SearchSort {
        switch self {
        case .dateAscSort:
            return .dateAscSort
        case .dateDescSort:
            return .dateDescSort
        case .relevance:
            return .ascSort
        }
    }
}
