//
//  If.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 29.10.2025.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
