//
//  GalleryModel.swift
//  GalleryFeature
//
//  Created by Ilia Lubianoi on 18.03.2026.
//

import Foundation

public struct GalleryModel: Identifiable, Hashable {
    
    public let id = UUID()
    public let urls: [URL]
    public let ids: [Int]?
    public let selectedId: Int
    
    public init(
        urls: [URL],
        ids: [Int]? = nil,
        selectedId: Int
    ) {
        self.urls = urls
        self.ids = ids
        self.selectedId = selectedId
    }
}
