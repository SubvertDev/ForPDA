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

extension SearchRequest {
    var transferSort: SearchCommand.SearchSort {
        switch sort {
        case .dateAscSort:
            return .dateAscSort
        case .dateDescSort:
            return .dateDescSort
        case .relevance:
            return .matchSort
        }
    }
    
    var transferOn: SearchCommand.SearchOn {
        switch on {
        case .site:
            return .site
        case let .forum(id, sIn, asTopics):
            let sIn: SearchCommand.ForumSearchIn = switch sIn {
            case .all:    .all
            case .posts:  .posts
            case .titles: .titles
            }
            return .forum(id: id, sIn: sIn, asTopics: asTopics)
        case let .topic(id, noHighlight):
            return .topic(id: id, noHighlight: noHighlight)
        case let .profile(sIn):
            let sIn: SearchCommand.ProfileSearchIn = switch sIn {
            case .posts:  .posts
            case .topics: .topics
            }
            return .profile(sIn)
        }
    }
}
