//
//  TicketStatusHistoryView.swift
//  ForPDA
//
//  Created by Xialtal on 10.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: TicketStatusHistoryFeature.self)
public struct TicketStatusHistoryView: View {
    
    @Perception.Bindable public var store: StoreOf<TicketStatusHistoryFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<TicketStatusHistoryFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                Text("Ticket Status History")
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
        TicketStatusHistoryView(
            store: Store(
                initialState: TicketStatusHistoryFeature.State(
                    ticketId: 0
                )
            ) {
                TicketStatusHistoryFeature()
            }
        )
    }
}
