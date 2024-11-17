//
//  DeveloperScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI

public struct NotificationsScreen: View {
    
    @Perception.Bindable public var store: StoreOf<NotificationsFeature>
    @Environment(\.tintColor) private var tintColor
    
    public init(store: StoreOf<NotificationsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color.Background.primary
                    .ignoresSafeArea()
                
                List {
                    Group {
                        if !store.areNotificationsEnabled {
                            VStack(spacing: 8) {
                                Text("Notifications are disabled")
                                    .multilineTextAlignment(.center)
                                    .listRowBackground(Color.Background.teritary)
                                    .frame(maxWidth: .infinity)
                                
                                Button {
                                    
                                } label: {
                                    Text("Open Settings")
                                }
                            }
                            .padding(16)
                        }
                        
                        Row("QMS", value: $store.isQmsEnabled)
                        Row("Forum", value: $store.isForumEnabled)
                        Row("Topics", value: $store.isTopicsEnabled)
                        Row("Forum mentions", value: $store.isForumMentionsEnabled)
                        Row("Site mentions", value: $store.isSiteMentionsEnabled)
                    }
                    .tint(tintColor)
                    .listRowBackground(Color.Background.teritary)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .frame(minHeight: 60)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Notifications", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
    
    @ViewBuilder
    private func Row(_ title: LocalizedStringKey, value: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Text(title, bundle: .module)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 8)
            
            Toggle(String(""), isOn: value)
        }
        .disabled(!store.areNotificationsEnabled)
    }
}

#Preview("Notifications Enabled") {
    NavigationStack {
        NotificationsScreen(store: Store(initialState: NotificationsFeature.State()) {
            NotificationsFeature()
        } withDependencies: {
            $0.notificationsClient.requestPermission = { true }
        })
    }
}

#Preview("Notifications Disabled") {
    NavigationStack {
        NotificationsScreen(store: Store(initialState: NotificationsFeature.State()) {
            NotificationsFeature()
        } withDependencies: {
            $0.notificationsClient.requestPermission = { false }
        })
    }
}
