//
//  ChatAction.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.11.2025.
//

import ExyteChat
import SwiftUI

enum ChatAction: MessageMenuAction {
    case copy
    
    func title() -> String {
        return String(localized: "Copy", bundle: .module)
    }
    
    func icon() -> Image {
        return Image(systemSymbol: .clipboard)
    }
}
