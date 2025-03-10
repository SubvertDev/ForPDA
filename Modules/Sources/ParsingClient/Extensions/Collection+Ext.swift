//
//  Collection+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 10.03.2025.
//

import Foundation

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
