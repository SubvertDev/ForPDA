//
//  ForumRowInfo.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 09.11.2024.
//

import Foundation
import Models

public struct ForumRowInfo: Equatable, Identifiable {
    public let id: Int
    public let title: String
    public var forums: [ForumInfo]
    
    public init(id: Int, title: String, forums: [ForumInfo]) {
        self.id = id
        self.title = title
        self.forums = forums
    }
}
