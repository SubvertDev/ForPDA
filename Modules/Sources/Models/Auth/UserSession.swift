//
//  UserSession.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.08.2024.
//

import Foundation

public struct UserSession: Sendable, Equatable, Codable {
    public let userId: Int
    public let token: String
    public let isHidden: Bool
    
    public init(userId: Int, token: String, isHidden: Bool) {
        self.userId = userId
        self.token = token
        self.isHidden = isHidden
    }
}

public extension UserSession {
    static let mock = mock()
    
    static func mock(
        userId: Int = 0,
        token: String = "",
        isHidden: Bool = false
    ) -> UserSession {
        return UserSession(
            userId: userId,
            token: token,
            isHidden: isHidden
        )
    }
}
