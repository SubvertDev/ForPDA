//
//  ProfileScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import SwiftUI
import ComposableArchitecture
import SkeletonUI
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
                    List {
                        VStack(spacing: 16) {
                            LazyImage(url: user.imageUrl) { state in
                                Group {
                                    if let image = state.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Color(.systemBackground)
                                    }
                                }
                                .skeleton(with: state.isLoading, shape: .circle)
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            
                            Text(user.nickname)
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color(.systemGroupedBackground))
                        
                        Section {
                            informationRow(
                                title: "Registration date",
                                description: user.registrationDate.formatted(date: .numeric, time: .omitted)
                            )
                            
                            if user.lastSeenDate.timeIntervalSince1970 > 86400 {
                                informationRow(
                                    title: "Last seen date",
                                    description: user.lastSeenDate.formatted(date: .numeric, time: .shortened)
                                )
                            }
                            
                            if !user.userCity.isEmpty {
                                informationRow(
                                    title: "City",
                                    description: user.userCity
                                )
                            }
                        } header: {
                            Text("Information", bundle: .module)
                        }
                        
                        Section {
                            informationRow(
                                title: "Karma",
                                description: String(format: "%.2f", (Double(user.karma) / 100))
                            )
                            
                            informationRow(
                                title: "Posts",
                                description: String(user.posts)
                            )
                            
                            informationRow(
                                title: "Comments",
                                description: String(user.comments)
                            )
                        } header: {
                            Text("Site statistics", bundle: .module)
                        }
                        
                        Section {
                            informationRow(
                                title: "Reputation",
                                description: String(user.reputation)
                            )
                            
                            informationRow(
                                title: "Topics",
                                description: String(user.topics)
                            )
                            
                            informationRow(
                                title: "Replies",
                                description: String(user.replies)
                            )
                        } header: {
                            Text("Forum statistics", bundle: .module)
                        }
                        
                        if store.shouldShowLogoutButton {
                            Button {
                                store.send(.logoutButtonTapped)
                            } label: {
                                Text("Logout", bundle: .module)
                            }
                        }
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
    
    @ViewBuilder
    private func informationRow(title: LocalizedStringKey, description: String) -> some View {
        HStack {
            Text(title, bundle: .module)
            
            Spacer()
            
            Text(description)
                .foregroundStyle(.secondary)
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
                $0.apiClient = .previewValue
            }
        )
    }
}
