//
//  Tag.swift
//  
//
//  Created by Ilia Lubianoi on 01.07.2024.
//

import Foundation

public struct Tag: Hashable {
    public let id: Int
    public let name: String
    
    public init(
        id: Int,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}
