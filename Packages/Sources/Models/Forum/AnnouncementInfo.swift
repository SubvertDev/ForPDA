//
//  AnnoucementInfo.swift
//  ForPDA
//
//  Created by Xialtal on 7.11.24.
//

public struct AnnouncementInfo: Sendable, Hashable, Codable, Identifiable {
    public let id: Int
    public let name: String
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public extension AnnouncementInfo {
    static let mock = AnnouncementInfo(
        id: 0,
        name: "This is really announcement?!"
    )
}
