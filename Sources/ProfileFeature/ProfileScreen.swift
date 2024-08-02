//
//  ProfileScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import SwiftUI
import ComposableArchitecture
import NukeUI

public struct ProfileScreen: View {
    
    public let store: StoreOf<ProfileFeature>
    
    public init(store: StoreOf<ProfileFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 0) {
                if let user = store.user {
                    LazyImage(url: user.imageUrl) { state in
                        if let image = state.image { image.resizable().scaledToFit() }
                    }
                    .frame(width: 100, height: 100)
                    
                    Text(user.nickname)
                    Text(user.registrationDate.formatted())
                    Text(user.lastSeenDate.formatted())
                    Text(user.userCity)
                    Text(String(user.karma))
                    Text(String(user.posts))
                    Text(String(user.comments))
                    Text(String(user.reputation))
                    Text(String(user.topics))
                    Text(String(user.replies))
                    
                    Button {
                        store.send(.logoutButtonTapped)
                    } label: {
                        Text("Logout", bundle: .module)
                    }
                } else {
                    ProgressView().id(UUID())
                }
            }
            .navigationTitle(Text("Profile", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                store.send(.onTask)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileScreen(
            store: Store(
                initialState: ProfileFeature.State(
                    userId: 3640948
                )
            ) {
                ProfileFeature()
            } withDependencies: {
                $0.apiClient = .liveValue
            }
        )
    }
}
