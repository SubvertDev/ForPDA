//
//  SettingsCellType.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit
import SFSafeSymbols

struct MenuSection {
    let title: String?
    var options: [MenuOptionType]
    
    init(title: String? = nil, options: [MenuOptionType]) {
        self.title = title
        self.options = options
    }
}

enum MenuOptionType {
    case authCell(model: MenuOption)
    case staticCell(model: MenuOption)
    case descriptionCell(model: DescriptionOption)
    case switchCell(model: SwitchOption)
}

struct MenuOption {
    let title: String
    let icon: SFSymbol?
    let image: UIImage?
    let handler: (() -> Void)
    
    init(title: String, icon: SFSymbol? = nil, image: UIImage? = nil, handler: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.image = image
        self.handler = handler
    }
}

struct DescriptionOption {
    let title: String
    let description: String
    let handler: (() -> Void)
}

struct SwitchOption {
    let title: String
    var isOn: Bool
    let handler: (() -> Void)
}
