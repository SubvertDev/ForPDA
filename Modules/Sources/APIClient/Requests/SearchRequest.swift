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
    public let author: SearchAuthorType?
    public let text: String
    public let sort: SearchSort
    public let offset: Int
    public let amount: Int
    
    public init(
        on: SearchOn,
        author: SearchAuthorType?,
        text: String,
        sort: SearchSort,
        offset: Int,
        amount: Int,
    ) {
        self.on = on
        self.author = author
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
    
    var transferAuthors: [SearchCommand.AuthorType] {
        return if let author {
            switch author {
            case .id(let id):     [.id(id)]
            case .name(let name): [.name(name)]
            }
        } else {
            []
        }
    }
    
    var transferOn: SearchCommand.SearchOn {
        switch on {
        case .site:
            return .site
        case let .forum(ids, sIn, asTopics):
            let sIn: SearchCommand.ForumSearchIn = switch sIn {
            case .all:    .all
            case .posts:  .posts
            case .titles: .titles
            }
            return .forum(ids: ids, sIn: sIn, asTopics: asTopics)
        case let .topic(ids, noHighlight):
            return .topic(ids: ids, noHighlight: noHighlight)
        case let .profile(sIn):
            let sIn: SearchCommand.ProfileSearchIn = switch sIn {
            case .posts:  .posts
            case .topics: .topics
            }
            return .profile(sIn)
        }
    }
}
