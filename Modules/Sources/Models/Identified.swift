//
//  IdentifiedURL.swift
//  Models
//
//  Created by Ilia Lubianoi on 26.04.2026.
//

import Foundation

public struct IdentifiedURL: Identifiable, Hashable, Sendable, Equatable {
    
    public var url: URL
    public var id: URL { url }
    
    public init(_ url: URL) {
        self.url = url
    }
}
