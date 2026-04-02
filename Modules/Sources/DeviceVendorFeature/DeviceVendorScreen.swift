//
//  DeviceVendorScreen.swift
//  ForPDA
//
//  Created by Xialtal on 2.04.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: DeviceVendorFeature.self)
public struct DeviceVendorScreen: View {
    
    @Perception.Bindable public var store: StoreOf<DeviceVendorFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<DeviceVendorFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                Text("Vendor")
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
        DeviceVendorScreen(
            store: Store(
                initialState: DeviceVendorFeature.State(
                    type: .phone,
                    vendorName: "apple"
                )
            ) {
                DeviceVendorFeature()
            }
        )
    }
}
