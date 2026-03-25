//
//  User.WarningLog+Extension.swift
//  ForPDA
//
//  Created by Xialtal on 24.03.26.
//

import SwiftUI
import Models
import SFSafeSymbols

extension User.WarningLog {
    var levelSymbol: SFSymbol {
        if #available(iOS 17.0, *) {
            return switch level {
            case .decreased: .arrowshapeDownFill
            case .increased: .arrowshapeUpFill
            case .notice:    ._2hCircle
            case .unknown:   .info
            }
        } else {
            return switch level {
            case .decreased: .arrowDown
            case .increased: .arrowUp
            case .notice:    .info
            case .unknown:   .info
            }
        }
    }
    
    var levelColor: Color {
        switch level {
        case .decreased: .green
        case .increased: .red
        case .notice:    .blue
        case .unknown:   .gray
        }
    }
    
    var levelTitle: LocalizedStringKey {
        switch level {
        case .decreased:
            LocalizedStringKey("Warning level decreased")
        case .increased:
            LocalizedStringKey("Warning level increased")
        case .notice:
            LocalizedStringKey("Note added")
        case .unknown:
            LocalizedStringKey("Unknown level")
        }
    }
}
