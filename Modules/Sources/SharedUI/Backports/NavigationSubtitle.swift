//
//  NavigationSubtitle.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 04.03.2026.
//

import SwiftUI

public extension View {
    func _navigationSubtitle(_ subtitle: Text) -> some View {
        if #available(iOS 26, *) {
            return navigationSubtitle(subtitle)
        } else {
            return self
        }
    }
}

