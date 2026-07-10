//
//  ListSectionSpacing.swift
//  ForPDA
//
//  Created by Xialtal on 27.03.26.
//

import SwiftUI

public extension View {
    @available(iOS, deprecated: 17.0, message: "Use native listSectionSpacing instead")
    func _listSectionSpacing(_ value: CGFloat) -> some View {
        self.modifier(ListSectionSpacing(value: value))
    }
}

private struct ListSectionSpacing: ViewModifier {
    
    var value: CGFloat
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .listSectionSpacing(value)
        } else {
            content
        }
    }
}
