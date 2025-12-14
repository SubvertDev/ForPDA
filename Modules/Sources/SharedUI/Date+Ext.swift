//
//  Date+Ext.swift
//  ForPDA
//
//  Created by Xialtal on 28.11.25.
//

import Foundation
import SwiftUI

extension Date {
    func formattedDate() -> LocalizedStringKey {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if Calendar.current.isDateInToday(self) {
            return LocalizedStringKey("Today, \(formatter.string(from: self))")
        } else if Calendar.current.isDateInYesterday(self) {
            return LocalizedStringKey("Yesterday, \(formatter.string(from: self))")
        } else {
            formatter.dateFormat = "dd.MM.yy, HH:mm"
            return LocalizedStringKey(formatter.string(from: self))
        }
    }
}
