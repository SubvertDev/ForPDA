//
//  ReputationChangeResponseType.swift
//  ForPDA
//
//  Created by Xialtal on 12.06.25.
//

public enum ReputationChangeResponseType: Int, Sendable {
    case success = 0
    case blocked = 4
    case selfChangeError = 5
    case notEnoughtPosts = 6
    case tooLowReputation = 7
    case cannotChangeToday = 8
    case cannotChangeTodayToThisUser = 9
    case cannotChangeForThisPost = 10
    case cannotChangeForThisUserNow = 11
    case thisPersonYouRecentlyDownvoted = 12
    case thisPersonRecentlyDownvotedYou = 13
    case error = -1
    
    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .success
        case 4: self = .blocked
        case 5: self = .selfChangeError
        case 6: self = .notEnoughtPosts
        case 7: self = .tooLowReputation
        case 8: self = .cannotChangeToday
        case 9: self = .cannotChangeTodayToThisUser
        case 10: self = .cannotChangeForThisPost
        case 11: self = .cannotChangeForThisUserNow
        case 12: self = .thisPersonYouRecentlyDownvoted
        case 13: self = .thisPersonRecentlyDownvotedYou
        default: self = .error
        }
    }
    
    public var isError: Bool {
        return self != .success
    }
}
