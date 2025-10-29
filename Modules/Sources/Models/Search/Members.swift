//
//  Members.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 29.10.2025.
//

import Foundation

public struct MembersResponse: Sendable, Hashable, Decodable {
    public let metadata: [Int]
    public let members: [Member]
    
    public init(
        metadata: [Int],
        members: [Member]
    ) {
        self.metadata = metadata
        self.members = members
    }
}

public struct Member: Sendable, Hashable, Decodable {
    public let id: Int
    public let nickname: String
    public let unknown3: Int
    public let avatarUrl: String
    
    public init(
        id: Int,
        nickname: String,
        unknown3: Int,
        avatarUrl: String
    ) {
        self.id = id
        self.nickname = nickname
        self.unknown3 = unknown3
        self.avatarUrl = avatarUrl
    }
}
