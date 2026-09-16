//
//  ReputationChangeContentType.swift
//  ForPDA
//
//  Created by Xialtal on 17.09.26.
//

public enum ReputationChangeContentType: Sendable, Equatable {
    case post(id: Int)
    case comment(id: Int)
    case profile
}
