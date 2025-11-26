//
//  SearchResponse.swift
//  ForPDA
//
//  Created by Xialtal on 26.11.25.
//

public struct SearchResponse: Sendable {
    public let content: [SearchContent]
    public let contentCount: Int
    
    public init(
        content: [SearchContent],
        contentCount: Int
    ) {
        self.content = content
        self.contentCount = contentCount
    }
}

public extension SearchResponse {
    static let mock = SearchResponse(
        content: [.article(.mock), .topic(.mockToday), .post(.mock)],
        contentCount: 3
    )
}
