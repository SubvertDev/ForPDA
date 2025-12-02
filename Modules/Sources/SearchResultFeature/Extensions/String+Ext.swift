//
//  String+Ext.swift
//  ForPDA
//
//  Created by Xialtal on 30.11.25.
//

extension String {
    func fixBackgroundBBCode() -> String {
        return self.replacingOccurrences(of: "[backgroud", with: "[background")
    }
    
    func removeSelectionBBCodes() -> String {
        return self.replacingOccurrences(of: "[backgroud=yellow][color=red]", with: "")
            .replacingOccurrences(of: "[/color][/background]", with: "")
    }
}
