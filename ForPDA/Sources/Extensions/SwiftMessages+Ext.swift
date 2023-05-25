//
//  SwiftMessages+Ext.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import SwiftMessages

extension SwiftMessages {
    
    static func showDefault(title: String, body: String) {
        SwiftMessages.show {
            let view = MessageView.viewFromNib(layout: .centeredView)
            view.configureTheme(backgroundColor: .systemBlue, foregroundColor: .white)
            view.configureDropShadow()
            view.configureContent(title: title, body: body)
            (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            view.button?.isHidden = true
            return view
        }
    }
}
