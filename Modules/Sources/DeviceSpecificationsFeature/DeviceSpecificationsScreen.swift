//
//  DeviceSpecificationsScreen.swift
//  ForPDA
//
//  Created by Xialtal on 23.12.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI

@ViewAction(for: DeviceSpecificationsFeature.self)
public struct DeviceSpecificationsScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<DeviceSpecificationsFeature>
    
    // MARK: - Init
    
    public init(store: StoreOf<DeviceSpecificationsFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let specifications = store.specifications, !store.isLoading {
                    Text(specifications.deviceName)
                }
            }
            .navigationTitle(Text("DevDB", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.Background.primary))
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeviceSpecificationsScreen(
            store: Store(
                initialState: DeviceSpecificationsFeature.State(
                    tag: "forpda",
                    subTag: nil
                ),
            ) {
                DeviceSpecificationsFeature()
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
