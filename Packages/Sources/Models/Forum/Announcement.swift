//
//  Announcement.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

public struct Announcement: Sendable, Hashable, Codable, Identifiable {
    public let id: Int
    public let name: String
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public extension Announcement {
    static let mock = Announcement(
        id: 0,
        name: "This is really announcement?!"
    )
}
