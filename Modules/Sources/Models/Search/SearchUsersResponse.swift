//
//  SearchUsersResponse.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.2025.
//

import Foundation

public struct SearchUsersResponse: Sendable, Hashable, Decodable {
    public let users: [SimplifiedUser]
    public let usersCount: Int
    
    public struct SimplifiedUser: Sendable, Identifiable, Hashable, Decodable {
        public let id: Int
        public let name: String
        public let groupId: Int
        public let avatarUrl: String
        
        public init(
            id: Int,
            name: String,
            groupId: Int,
            avatarUrl: String
        ) {
            self.id = id
            self.name = name
            self.groupId = groupId
            self.avatarUrl = avatarUrl
        }
    }
    
    public init(
        users: [SimplifiedUser],
        usersCount: Int
    ) {
        self.users = users
        self.usersCount = usersCount
    }
}

public extension SearchUsersResponse {
    static let mock = SearchUsersResponse(
        users: [
            .init(
                id: 1,
                name: "AirFlare",
                groupId: 3,
                avatarUrl: ""
            ),
            .init(
                id: 2,
                name: "subvertd",
                groupId: 3,
                avatarUrl: ""
            )
        ],
        usersCount: 2
    )
}
