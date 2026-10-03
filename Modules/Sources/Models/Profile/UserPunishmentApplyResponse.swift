//
//  UserPunishmentApplyResponse.swift
//  ForPDA
//
//  Created by Xialtal on 11.09.26.
//

public enum UserPunishmentApplyResponse: Int, Sendable {
    case success = 0
    case reasonNotSet = 5
    case messageNotSet = 6
    case warningLevelMax = 7
    case needConfirmation = 8
    
    case noAccess
}
