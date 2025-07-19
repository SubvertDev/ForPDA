//
//  Announcement.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

public struct Announcement: Codable, Sendable, Hashable {
    public let name: String
    public let content: String
    
    public init(name: String, content: String) {
        self.name = name
        self.content = content
    }
}

public extension Announcement {
    static let mock = Announcement(
        name: "FourPDA now support forum?",
        content: "Yes, FourPDA now support forum."
    )
}
