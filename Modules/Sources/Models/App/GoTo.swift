//
//  GoTo.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 05.04.2025.
//

public enum GoTo: Equatable {
    case first
    case unread
    case post(id: Int)
    case last
}
