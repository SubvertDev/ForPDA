//
//  TopicViewers.swift
//  ForPDA
//
//  Created by Xialtal on 24.03.26.
//

public struct TopicViewers: Sendable {
    public let guestsCount: Int
    public let hiddenUsersCount: Int
    public let users: [SimplifiedUser]
    
    public struct SimplifiedUser: Sendable, Identifiable {
        public let id: Int
        public let name: String
        public let group: User.Group
        
        public init(
            id: Int,
            name: String,
            group: User.Group
        ) {
            self.id = id
            self.name = name
            self.group = group
        }
    }
    
    public init(
        guestsCount: Int,
        hiddenUsersCount: Int,
        users: [SimplifiedUser]
    ) {
        self.guestsCount = guestsCount
        self.hiddenUsersCount = hiddenUsersCount
        self.users = users
    }
}

public extension TopicViewers {
    static let mock = TopicViewers(
        guestsCount: 1,
        hiddenUsersCount: 2,
        users: [
            .init(id: 0, name: "AirFlare", group: .regular),
            .init(id: 1, name: "subvertd", group: .regular),
            .init(id: 2, name: "Another", group: .active)
        ]
    )
}
