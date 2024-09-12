//
//  ForumScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.09.2024.
//

import SwiftUI
import ComposableArchitecture
import SFSafeSymbols
import SharedUI

public struct ForumScreen: View {
    
    @Perception.Bindable public var store: StoreOf<ForumFeature>
    
    public init(store: StoreOf<ForumFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            List(store.forums, id: \.self) { forum in
                WithPerceptionTracking {
                    Text(forum.name)
                }
            }
            .navigationTitle(Text("Forum", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                store.send(.onTask)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ForumScreen(
            store: Store(
                initialState: ForumFeature.State()
            ) {
                ForumFeature()
            }
        )
    }
}
