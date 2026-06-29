//
//  UserPunishmentScreen.swift
//  ForPDA
//
//  Created by Xialtal on 28.06.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: UserPunishmentFeature.self)
public struct UserPunishmentScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<UserPunishmentFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<UserPunishmentFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView {
                Text("Punishment", bundle: .module)
            }
            .background(Color(.Background.primary))
            .onAppear {
                send(.onAppear)
            }
        }
    }
}

// MARK: - Extensions

extension Binding where Value == UserPunishmentTemplateFlag {
    func options(_ options: Value) -> Binding<Bool> {
        return .init { () -> Bool in
            wrappedValue.contains(options)
        } set: { newValue in
            if newValue {
                wrappedValue.insert(options)
            } else {
                wrappedValue.remove(options)
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        UserPunishmentScreen(
            store: Store(
                initialState: UserPunishmentFeature.State(
                    userId: 6176341,
                    target: .reputation(id: 123456)
                )
            ) {
                UserPunishmentFeature()
            }
        )
    }
}
