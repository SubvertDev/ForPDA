//
//  SearchResult.swift
//  ForPDA
//
//  Created by Xialtal on 29.11.25.
//

public struct SearchResult: Sendable, Equatable {
    public let on: SearchOn
    public let authorId: Int?
    public let text: String
    public let sort: SearchSort
    
    public init(
        on: SearchOn,
        authorId: Int?,
        text: String,
        sort: SearchSort
    ) {
        self.on = on
        self.authorId = authorId
        self.text = text
        self.sort = sort
    }
}

public extension SearchResult {
    static let mock = SearchResult(
        on: .site,
        authorId: nil,
        text: "ForPDA",
        sort: .relevance
    )
}
