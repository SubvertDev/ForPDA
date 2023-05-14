//
//  SettingsCellType.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit
import SFSafeSymbols

struct MenuSection {
//    let title: String
    let options: [MenuOptionType]
}

enum MenuOptionType {
    case authCell(model: MenuOption)
    case staticCell(model: MenuOption)
    //case switchCell(model: SettingsSwitchOption)
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

//struct SettingsSwitchOption {
//    let title: String
//    let icon: UIImage?
//    let iconBackgroundColor: UIColor
//    let handler: (() -> Void)
//    var isOn: Bool
//}
