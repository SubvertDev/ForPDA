//
//  OnFirstAppear.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.06.2025.
//

import SwiftUI

public extension View {
    func onFirstAppear(
        _ onFirstAction: @escaping () -> (),
        onNextAppear onNextAction: @escaping () -> () = {}
    ) -> some View {
        modifier(OnAppears(onFirstAction: onFirstAction, onNextAction: onNextAction))
    }
}

private struct OnAppears: ViewModifier {
    
    @State private var hasAppearedOnce = false
    
    let onFirstAction: () -> ()
    let onNextAction: () -> ()
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                if hasAppearedOnce {
                    onNextAction()
                } else {
                    hasAppearedOnce = true
                    onFirstAction()
                }
            }
    }
}
