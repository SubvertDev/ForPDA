//
//  CommentResponseType.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 27.09.2024.
//

import SwiftUI

public enum CommentResponseType: Int, Sendable {
    case success = 0
    case accessDenied = 4
    case emptyMessage = 5
    case postExpired = 6
    case hiddenDenied = 7
    case limitExceeded = 8
    case repeatedComment = 9
    case hourLimitExceeded = 10
    case dayLimitExceeded = 11
    case unknown = 14
    
    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .success
        case 4: self = .accessDenied
        case 5: self = .emptyMessage
        case 6: self = .postExpired
        case 7: self = .hiddenDenied
        case 8: self = .limitExceeded
        case 9: self = .repeatedComment
        case 10: self = .hourLimitExceeded
        case 11: self = .dayLimitExceeded
        case 12, 13: self = .unknown; print(">>> GOT UNKNOWN ERROR ON COMMENT") // TODO: Check case
        default: self = .success
        }
    }
    
    public static var codes: [Int] {
        return [0,4,5,6,7,8,9,10,11,12,13]
    }
    
    public var description: LocalizedStringKey {
        switch self {
        case .success:              return "Comment has been added"
        case .accessDenied:         return "You're not allowed to comment"
        case .emptyMessage:         return "No comment text"
        case .postExpired:          return "Commenting on this post is closed"
        case .hiddenDenied:         return "You cannot reply to a comment you have hidden"
        case .limitExceeded:        return "You've hit the carmine limit"
        case .repeatedComment:      return "Repeated comment"
        case .hourLimitExceeded:    return "You've hit the hourly commenting limit"
        case .dayLimitExceeded:     return "You've hit the daily commenting limit"
        case .unknown:              return "Unknown error"
        }
    }
    
    public var isError: Bool {
        if case .success = self {
            return false
        } else {
            return true
        }
    }
}
