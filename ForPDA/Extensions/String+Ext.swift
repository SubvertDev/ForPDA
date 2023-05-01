//
//  String+Ext.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import Foundation

extension String {
    
    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex
        
        while searchStartIndex < self.endIndex,
              let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
              !range.isEmpty {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }
        
        return indices
    }
    
    func stripLastURLComponent() -> String {
        guard var url = URL(string: self) else { return self }
        url.deleteLastPathComponent()
        print(url.absoluteString)
        return url.absoluteString
    }
    
}
