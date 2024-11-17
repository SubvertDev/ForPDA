//
//  QMSList.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation

public struct QMSList: Sendable, Codable, Hashable {
    public var users: [QMSUser]
    
    public init(users: [QMSUser]) {
        self.users = users
    }
}
