//
//  ReputationScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//
import Foundation
import SwiftUI
import ComposableArchitecture
import SharedUI

@ViewAction(for: ReputationFeature.self)
public struct ReputationScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ReputationFeature>
    
    public init(store: StoreOf<ReputationFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                Text("Reputation view")
            }
            .navigationTitle(Text("Reputation", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReputationScreen(
            store: Store(
                initialState: ReputationFeature.State()
            ) {
                ReputationFeature()
            }
        )
    }
}
