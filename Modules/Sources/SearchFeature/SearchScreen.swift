//
//  SearchScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import SwiftUI
import SharedUI
import ComposableArchitecture

@ViewAction(for: SearchFeature.self)
public struct SearchScreen: View {
    @Perception.Bindable public var store: StoreOf<SearchFeature>
    
    public init(store: StoreOf<SearchFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                Button {
                    store.send(.internal(.search("Test")))
                } label: {
                    Text("Search Screen")
                }
            }
            .navigationTitle("Search")
        }
    }
}

#Preview {
    SearchScreen(
        store: Store(
            initialState: SearchFeature.State(),
        ) {
            SearchFeature()
        }
    )
}
