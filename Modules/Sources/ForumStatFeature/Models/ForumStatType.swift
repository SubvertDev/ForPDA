//
//  ForumStatType.swift
//  ForPDA
//
//  Created by Xialtal on 24.03.26.
//

import Models

public enum ForumStatType: Equatable {
    case topic(Topic)
    case forum(id: Int)
}
