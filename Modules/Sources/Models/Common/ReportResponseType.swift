//
//  ReportResponseType.swift
//  ForPDA
//
//  Created by Xialtal on 5.04.25.
//

public enum ReportResponseType: Int, Sendable {
    case tooShort = 4
    case success = 0
    case error = -1
    
    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .success
        case 4: self = .tooShort
        default: self = .error
        }
    }
    
    public var isError: Bool {
        return self != .success
    }
}
