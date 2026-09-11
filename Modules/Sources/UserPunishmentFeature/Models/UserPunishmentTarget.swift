//
//  UserPunishmentTarget.swift
//  ForPDA
//
//  Created by Xialtal on 28.06.26.
//

public enum UserPunishmentTarget: Sendable, Equatable {
    case post(id: Int)
    case reputation(id: Int)
    case profile
    
    var id: Int {
        switch self {
        case .profile: 0
        case let .post(id): id
        case let .reputation(id): -id
        }
    }
}
