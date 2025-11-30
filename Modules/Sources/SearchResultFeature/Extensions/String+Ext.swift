//
//  String+Ext.swift
//  ForPDA
//
//  Created by Xialtal on 30.11.25.
//

extension String {
    func fixBBCode() -> String {
        return self.replacingOccurrences(of: "[backgroud", with: "[background")
    }
}
