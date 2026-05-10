//
//  Redacted.swift
//  SharedUI
//
//  Created by Ilia Lubianoi on 10.05.2026.
//

import SwiftUI

public extension View {
    
    @ViewBuilder
    func redacted(if condition: @autoclosure () -> Bool) -> some View {
        redacted(reason: condition() ? .placeholder : [])
    }
}
