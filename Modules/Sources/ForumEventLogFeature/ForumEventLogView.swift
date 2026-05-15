//
//  ForumEventLogView.swift
//  ForPDA
//
//  Created by Xialtal on 14.05.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: ForumEventLogFeature.self)
public struct ForumEventLogView: View {
    
    @Perception.Bindable public var store: StoreOf<ForumEventLogFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<ForumEventLogFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                Text("Forum Event Log")
            }
            .background(Color(.Background.primary))
            .onAppear {
                send(.onAppear)
            }
        }
    }
}

// MARK: - Previews

#Preview("Post Events") {
    NavigationStack {
        ForumEventLogView(
            store: Store(
                initialState: ForumEventLogFeature.State(
                    id: 0,
                    type: .post
                )
            ) {
                ForumEventLogFeature()
            }
        )
    }
}

#Preview("Topic Events") {
    NavigationStack {
        ForumEventLogView(
            store: Store(
                initialState: ForumEventLogFeature.State(
                    id: 0,
                    type: .topic
                )
            ) {
                ForumEventLogFeature()
            }
        )
    }
}
