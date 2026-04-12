//
//  UserNoteResponse.swift
//  ForPDA
//
//  Created by Xialtal on 12.04.26.
//

public enum UserNoteResponse: Int, Sendable {
    case reasonNotSet = 5
    case success = 0
    case error = -1
    
    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .success
        case 5: self = .reasonNotSet
        default: self = .error
        }
    }
}
