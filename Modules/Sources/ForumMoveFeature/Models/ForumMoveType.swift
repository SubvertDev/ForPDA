//
//  ForumMoveType.swift
//  ForPDA
//
//  Created by Xialtal on 11.04.26.
//

import Foundation

public enum ForumMoveType: Equatable {
    case topic(Int)
    case posts([Int])
}

