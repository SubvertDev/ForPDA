//
//  SettingsCellType.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit

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
    let icon: UIImage
    let handler: (() -> Void)
}

//struct SettingsSwitchOption {
//    let title: String
//    let icon: UIImage?
//    let iconBackgroundColor: UIColor
//    let handler: (() -> Void)
//    var isOn: Bool
//}
