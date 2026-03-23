//
//  User.Gender+Extension.swift
//  ForPDA
//
//  Created by Xialtal on 9.11.25.
//

import SwiftUI
import Models

extension User.Gender {
    var title: LocalizedStringKey {
        switch self {
        case .unknown:
            "Not set"
        case .male:
            "Male"
        case .female:
            "Female"
        }
    }
}
