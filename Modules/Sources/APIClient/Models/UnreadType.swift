//
//  UnreadType.swift
//  ForPDA
//
//  Created by Xialtal on 20.03.26.
//

import Models

public enum UnreadType: Sendable {
    case all
    case category(Unread.Item.Category, timestamp: Int)
}
