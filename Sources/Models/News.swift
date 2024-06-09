//
//  News.swift
//
//
//  Created by Ilia Lubianoi on 26.05.2024.
//

import Foundation

public struct News: Equatable, Hashable {
    public var preview: NewsPreview
    public var elements: [NewsElement]
    
    public var url: URL {
        return preview.url
    }
    
    public init(
        preview: NewsPreview,
        elements: [NewsElement] = []
    ) {
        self.preview = preview
        self.elements = elements
    }
}
