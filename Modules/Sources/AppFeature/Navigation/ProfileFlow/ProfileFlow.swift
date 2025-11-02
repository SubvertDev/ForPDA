//
//  ProfileFlow.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 26.10.2025.
//

import ComposableArchitecture
import SwiftUI

// MARK: - Domain

@Reducer
public enum ProfileFlow {
    case loggedIn(StackTab)
    case loggedOut(StackTab)
}

extension ProfileFlow.State: Equatable { }

// MARK: - View

public struct ProfileTab: View {
    
    public let store: StoreOf<ProfileFlow>
    
    public init(store: StoreOf<ProfileFlow>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            switch store.case {
            case let .loggedIn(store):
                StackTabView(store: store)
            case let .loggedOut(store):
                StackTabView(store: store)
            }
        }
    }
}
