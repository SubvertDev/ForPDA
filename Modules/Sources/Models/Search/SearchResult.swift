//
//  SearchResult.swift
//  ForPDA
//
//  Created by Xialtal on 29.11.25.
//

public struct SearchResult: Sendable, Equatable {
    public let on: SearchOn
    public let author: SearchAuthorType?
    public let text: String
    public let sort: SearchSort
    
    public init(
        on: SearchOn,
        author: SearchAuthorType?,
        text: String,
        sort: SearchSort
    ) {
        self.on = on
        self.author = author
        self.text = text
        self.sort = sort
    }
}

public extension SearchResult {
    static let mock = SearchResult(
        on: .site,
        author: nil,
        text: "ForPDA",
        sort: .relevance
    )
}
