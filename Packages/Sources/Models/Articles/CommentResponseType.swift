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
    case error = 14 //
    
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
        case .error:                return "Error adding comment"
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
