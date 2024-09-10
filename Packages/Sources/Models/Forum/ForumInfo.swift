//
//  ForumInfo.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

public struct ForumInfo: Sendable, Hashable, Codable {
    public let id: Int
    public let name: String
    public let flag: Int // 64
    public let redirectUrl: Optional<String>
    
    public init(
        id: Int,
        name: String,
        flag: Int,
        redirectUrl: Optional<String> = .none
    ) {
        self.id = id
        self.name = name
        self.flag = flag
        self.redirectUrl = redirectUrl
    }
}
