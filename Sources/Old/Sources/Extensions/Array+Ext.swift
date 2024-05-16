//
//  Array+Ext.swift
//  ForPDA
//
//  Created by Subvert on 13.05.2023.
//

import Foundation

extension Array {
    
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else { return nil }
        return self[index]
    }
}
