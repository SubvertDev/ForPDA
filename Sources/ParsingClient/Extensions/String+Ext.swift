//
//  String+Ext.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.07.2024.
//

import Foundation

extension String {
    func convertUnicodes() -> String {
        var string = self
        
        let pattern = /&#(\d+);/
        
        for match in string.matches(of: pattern).reversed() {
            let input = match.output.0
            let numeric = Int(input.dropFirst(2).dropLast(1))!
            let scalar = Unicode.Scalar(numeric)!
            let output = String(Character(scalar))
            string = string.replacingOccurrences(of: input, with: output)
        }
        
        return string
    }
}
