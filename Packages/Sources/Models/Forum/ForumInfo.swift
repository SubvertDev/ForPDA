//
//  ForumInfo.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

public struct ForumInfo: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let flag: Int
    public let redirectUrl: String?
    
    public var isCategory: Bool {
         return (flag & 16) != 0
    }
    
    public var isUnread: Bool {
        return (flag & 32) > 0
    }
    
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

public extension ForumInfo {
    static let mock = ForumInfo(
        id: 5,
        name: "Site work",
        flag: 0
    )
    
    static let mockCategory = ForumInfo(
        id: 200,
        name: "Administrative",
        flag: 16
    )
}
