//
//  DeviceType+Extension.swift
//  ForPDA
//
//  Created by Xialtal on 3.04.26.
//

import SwiftUI
import Models
import SFSafeSymbols

extension DeviceType {
    var title: LocalizedStringKey {
        switch self {
        case .phone:      "Phones"
        case .ebook:      "E-Books"
        case .pad:        "Pads"
        case .smartWatch: "Smart Watch"
        }
    }
    
    var icon: SFSymbol {
        if #available(iOS 17.0, *) {
            switch self {
            case .phone:      .smartphone
            case .ebook:      .bookPages
            case .pad:        .ipadSizes
            case .smartWatch: .applewatch
            }
        } else {
            switch self {
            case .phone:      .phone
            case .ebook:      .book
            case .pad:        .ipadLandscape
            case .smartWatch: .applewatch
            }
        }
    }
}
