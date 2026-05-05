//
//  TicketScreen.swift
//  ForPDA
//
//  Created by Xialtal on 5.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: TicketFeature.self)
public struct TicketScreen: View {
    
    @Perception.Bindable public var store: StoreOf<TicketFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<TicketFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                Text("Ticket")
            }
            .background(Color(.Background.primary))
            .onAppear {
                send(.onAppear)
            }
        }
    }
}

// MARK: - Previews

#Preview("Ticket Single") {
    NavigationStack {
        TicketScreen(
            store: Store(
                initialState: TicketFeature.State(
                    type: .single(id: 0)
                )
            ) {
                TicketFeature()
            }
        )
    }
}

#Preview("Tickets List") {
    NavigationStack {
        TicketScreen(
            store: Store(
                initialState: TicketFeature.State(
                    type: .list(forId: 0)
                )
            ) {
                TicketFeature()
            }
        )
    }
}
