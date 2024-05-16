//
//  SettingsScreen.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI
import ComposableArchitecture

public struct SettingsScreen: View {
    
    @Perception.Bindable public var store: StoreOf<SettingsFeature>
    
    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    SettingsScreen(
        store: Store(
            initialState: SettingsFeature.State()
        ) {
            SettingsFeature()
        }
    )
}
