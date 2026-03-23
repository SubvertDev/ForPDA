//
//  ForumInfo.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct ForumInfo: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String
    public let flag: ForumFlag
    public let redirectUrl: URL?
    
    public var isCategory: Bool {
        return flag.contains(.marker)
    }
    
    public var isUnread: Bool {
        return flag.contains(.updated)
    }
    
    public var isFavorite: Bool {
        return flag.contains(.favorite)
    }
    
    public init(
        id: Int,
        name: String,
        flag: ForumFlag,
        redirectUrl: URL? = nil
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
        flag: []
    )
    
    static let mockCategory = ForumInfo(
        id: 200,
        name: "Administrative",
        flag: .marker
    )
}
