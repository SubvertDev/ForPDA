//
//  ForumScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
//

import SwiftUI
import ComposableArchitecture

public struct ForumScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ForumFeature>
    
    public init(
        store: StoreOf<ForumFeature>
    ) {
        self.store = store
    }
    
    public var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    ForumScreen(
        store: Store(
            initialState: ForumFeature.State()
        ) {
            ForumFeature()
        }
    )
}
