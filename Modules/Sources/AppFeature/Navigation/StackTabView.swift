//
//  StackTabView.swift
//  AppFeature
//
//  Created by Ilia Lubianoi on 30.03.2025.
//

import SwiftUI
import ComposableArchitecture

public struct StackTabView: View {
    
    @Bindable public var store: StoreOf<StackTab>
    
    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            Path.view(store.scope(state: \.root, action: \.root))
        } destination: { store in
            Path.view(store)
        }
        .toolbar(store.showTabBar ? .visible : .hidden, for: .tabBar)
        .animation(.default, value: store.root) // Animation for root change
        .onAppear { store.send(.onAppear) }
    }
}
