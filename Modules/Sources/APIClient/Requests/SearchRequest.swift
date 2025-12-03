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
    public let amount: Int
    
    public init(
        on: SearchOn,
        authorId: Int?,
        text: String,
        sort: SearchSort,
        offset: Int,
        amount: Int,
    ) {
        self.on = on
        self.authorId = authorId
        self.text = text
        self.sort = sort
        self.offset = offset
        self.amount = amount
    }
}

extension Models.SearchSort {
    func toPDAPISearchSort() -> SearchCommand.SearchSort {
        switch self {
        case .dateAscSort:
            return .dateAscSort
        case .dateDescSort:
            return .dateDescSort
        case .relevance:
            return .matchSort
        }
    }
}

extension Models.SearchOn {
    func toPDAPISearchOn() -> SearchCommand.SearchOn {
        switch self {
        case .site:
            return .site
        case let .forum(id, sIn, asTopics):
            return .forum(id: id, sIn: sIn.toPDAPIForumSearchIn(), asTopics: asTopics)
        case let .topic(id, noHighlight):
            return .topic(id: id, noHighlight: noHighlight)
        }
    }
}

fileprivate extension Models.ForumSearchIn {
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
