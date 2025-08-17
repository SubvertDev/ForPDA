//
//  SearchScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 17.08.2025.
//

import SwiftUI
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
            VStack {
                Text("Search Screen")
            }
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
