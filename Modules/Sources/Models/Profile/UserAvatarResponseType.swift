//
//  UserAvatarResponseType.swift
//  ForPDA
//
//  Created by Xialtal on 29.08.25.
//

import Foundation

public enum UserAvatarResponseType: Sendable {
    case error
    case success(URL?)
}
