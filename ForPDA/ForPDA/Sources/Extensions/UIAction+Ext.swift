//
//  UIAction+Ext.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import UIKit
import SFSafeSymbols

extension UIAction {
    static func make(title: String, symbol: SFSymbol, action: @escaping (UIAction) -> Void) -> UIAction {
        return UIAction(title: title, image: UIImage(systemSymbol: symbol), handler: action)
    }
}

extension UIContextMenuConfiguration {
    static func make(actions: [UIAction]) -> UIContextMenuConfiguration {
        return UIContextMenuConfiguration(actionProvider: { _ in
            return UIMenu(options: .displayInline, children: actions)
        })
    }
}
