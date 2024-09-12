//
//  ForumInfo.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

public struct ForumInfo: Sendable, Hashable, Decodable {
    public let id: Int
    public let name: String
    public let flag: Int
    public let redirectUrl: String?
    
    public init(
        id: Int,
        name: String,
        flag: Int,
        redirectUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.flag = flag
        self.redirectUrl = redirectUrl
    }
}
