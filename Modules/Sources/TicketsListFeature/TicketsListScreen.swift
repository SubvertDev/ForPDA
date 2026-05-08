//
//  TicketsListScreen.swift
//  ForPDA
//
//  Created by Xialtal on 8.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: TicketsListFeature.self)
public struct TicketsListScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<TicketsListFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<TicketsListFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                Text("Tickets List")
            }
            .background(Color(.Background.primary))
            .onAppear {
                send(.onAppear)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        TicketsListScreen(
            store: Store(
                initialState: TicketsListFeature.State(
                    forId: 0
                )
            ) {
                TicketsListFeature()
            }
        )
    }
}
