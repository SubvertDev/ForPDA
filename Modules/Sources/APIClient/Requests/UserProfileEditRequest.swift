//
//  UserProfileEditRequest.swift
//  ForPDA
//
//  Created by Xialtal on 2.09.25.
//

import Foundation
import Models
import PDAPI

public struct UserProfileEditRequest: Sendable {
    public let userId: Int
    public let city: String
    public let about: String
    public let gender: User.Gender
    public let status: String
    public let signature: String
    public let birthdayDate: Date?
    
    public init(
        userId: Int,
        city: String,
        about: String,
        gender: User.Gender,
        status: String,
        signature: String,
        birthdayDate: Date?
    ) {
        self.userId = userId
        self.city = city
        self.about = about
        self.gender = gender
        self.status = status
        self.signature = signature
        self.birthdayDate = birthdayDate
    }
}

extension UserProfileEditRequest {
    var transferGender: MemberProfileRequest.Gender {
        switch gender {
        case .male:    return .male
        case .female:  return .female
        case .unknown: return .unknown
        }
    }
}
