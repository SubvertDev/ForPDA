//
//  OnFirstAppear.swift
//
//
//  Created by Ilia Lubianoi on 04.07.2024.
//

import SwiftUI

public struct OnFirstAppear: ViewModifier {
    public let action: () -> ()
    
    // Use this to ensure the block is only executed once
    @State private var hasAppeared = false
    
    public func body(content: Content) -> some View {
        content.task {
            // Prevent the action from being executed more than once
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}

public extension View {
    func onFirstAppear(_ action: @escaping () -> ()) -> some View {
        modifier(OnFirstAppear(action: action))
    }
}
