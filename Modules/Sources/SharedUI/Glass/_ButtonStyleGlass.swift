//
//  ButtonStyleGlass.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 30.11.2025.
//

import SwiftUI

public struct _ButtonStyleGlass: ViewModifier {
    
    let isProminent: Bool
    
    public init(isProminent: Bool = false) {
        self.isProminent = isProminent
    }
    
    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if isProminent {
                content
                    .buttonStyle(.glassProminent)
            } else {
                content
                    .buttonStyle(.glass)
            }
        } else {
            content
        }
    }
}

public extension View {
    func _buttonStyleGlass(isProminent: Bool = false) -> some View {
        modifier(_ButtonStyleGlass(isProminent: isProminent))
    }
}
