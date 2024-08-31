//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 20.05.2024.
//

import SwiftUI

public extension LocalizedStringKey {
    func toString() -> String {
        let attributeLabelAndValue = Mirror(reflecting: self).children.first { (label, _) in label == "key" }
        if let keyValue = attributeLabelAndValue?.value as? String {
            return String.localizedStringWithFormat(NSLocalizedString(keyValue, comment: ""))
        } else {
            return "Swift LocalizedStringKey signature might have changed. Refer to Apple's documentation."
        }
    }
}
