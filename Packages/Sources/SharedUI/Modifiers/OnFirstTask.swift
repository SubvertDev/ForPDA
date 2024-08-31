//
//  OnFirstTask.swift
//
//
//  Created by Ilia Lubianoi on 04.07.2024.
//

import SwiftUI

public struct OnFirstTask: ViewModifier {
    public let action: @Sendable () async -> ()
    
    // Use this to ensure the block is only executed once
    @State private var hasAppeared = false
    
    public func body(content: Content) -> some View {
        content.task {
            // Prevent the action from being executed more than once
            guard !hasAppeared else { return }
            hasAppeared = true
            await action()
        }
    }
}

public extension View {
    func onFirstTask(_ action: @escaping @Sendable () async -> ()) -> some View {
        modifier(OnFirstTask(action: action))
    }
}
