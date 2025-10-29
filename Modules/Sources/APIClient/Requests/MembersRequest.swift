//
//  MembersRequest.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 29.10.2025.
//

import PDAPI
import Models

public struct MembersRequest: Sendable, Equatable {
    
    public let term: String
    public let offset: Int
    public let number: Int
    
    public init(
        term: String,
        offset: Int,
        number: Int
    ) {
        self.term = term
        self.offset = offset
        self.number = number
    }
}


