//
//  SearchRequest.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 18.08.2025.
//

import PDAPI

public struct SearchRequest: Sendable {
    
    public let on: SearchOn
    public let authorId: Int?
    public let text: String
    public let sort: SearchSort
    public let offset: Int
    
    public enum SearchOn: Sendable {
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
