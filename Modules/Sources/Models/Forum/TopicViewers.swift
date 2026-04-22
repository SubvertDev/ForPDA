//
//  TopicViewers.swift
//  ForPDA
//
//  Created by Xialtal on 24.03.26.
//

public struct TopicViewers: Sendable, Equatable {
    public let guestsCount: Int
    public let hiddenUsersCount: Int
    public let users: [SimplifiedUser]
    
    public var allCount: Int {
        return guestsCount + hiddenUsersCount + users.count
    }
    
    public struct SimplifiedUser: Sendable, Identifiable, Equatable {
        public let id: Int
        public let name: String
        public let group: User.Group
        public let isHidden: Bool
        
        public init(
            id: Int,
            name: String,
            group: User.Group,
            isHidden: Bool
        ) {
            self.id = id
            self.name = name
            self.group = group
            self.isHidden = isHidden
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
        hiddenUsersCount: 1,
        users: [
            .init(id: 0, name: "AirFlare", group: .regular, isHidden: true),
            .init(id: 1, name: "subvertd", group: .regular, isHidden: false),
            .init(id: 2, name: "Another", group: .active, isHidden: false)
        ]
    )
}
