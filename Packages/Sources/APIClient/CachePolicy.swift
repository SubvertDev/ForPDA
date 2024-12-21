//
//  CachePolicy.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.12.2024.
//

import Foundation

public enum CachePolicy: Sendable {
    case skipCache
    case cacheOrLoad
    case cacheAndLoad
    case cacheNoLoad
}
