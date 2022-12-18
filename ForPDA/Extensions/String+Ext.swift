//
//  String+Ext.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import Foundation

extension String {
    func converted() -> Self {
        return String(data: self.data(using: .windowsCP1252)!, encoding: .windowsCP1251)!
    }
    
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
              !range.isEmpty
        {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        
        return indices
    }
}
