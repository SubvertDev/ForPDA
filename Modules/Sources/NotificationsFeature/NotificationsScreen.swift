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
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List {
                    Section {
                        if !store.areNotificationsEnabled {
                            VStack(spacing: 8) {
                                Text("Notifications are disabled", bundle: .module)
                                    .multilineTextAlignment(.center)
                                    .listRowBackground(Color(.Background.teritary))
                                    .frame(maxWidth: .infinity)
                                
                                Button {
                                    let url = URL(string: UIApplication.openSettingsURLString)!
                                    UIApplication.shared.open(url)
                                } label: {
                                    Text("Open Settings", bundle: .module)
                                }
                            }
                            .padding(16)
                        }
                        
                        Row("QMS", value: $store.appSettings.notifications.isQmsEnabled)
                        Row("Forum", value: $store.appSettings.notifications.isForumEnabled)
                        Row("Topics", value: $store.appSettings.notifications.isTopicsEnabled)
                        Row("Forum mentions", value: $store.appSettings.notifications.isForumMentionsEnabled)
                        Row("Site mentions", value: $store.appSettings.notifications.isSiteMentionsEnabled)
                    } header: {
                        Text("General", bundle: .module)
                    }
                    .tint(tintColor)
                    .listRowBackground(Color(.Background.teritary))
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    
                    Section {
                        Row("Background notifications", value: $store.appSettings.backgroundNotifications2)
                        
                        if store.appSettings.backgroundNotifications {
                            Button {
                                store.send(.sendLogButtonTapped)
                            } label: {
                                HStack {
                                    Text("Send log", bundle: .module)
                                    Spacer()
                                    Image(systemSymbol: .squareAndArrowUp)
                                }
                            }
                        }
                    } header: {
                        Text("Experimental", bundle: .module)
                    }
                    .tint(tintColor)
                    .listRowBackground(Color(.Background.teritary))
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
                .animation(.default, value: store.appSettings.backgroundNotifications2)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Notifications", bundle: .module))
            ._toolbarTitleDisplayMode(.inline)
            .sheet(item: $store.logURL, id: \.self) { url in
                WithPerceptionTracking {
                    ShareActivityView(url: url, onDismiss: { _ in })
                        .presentationDetents([.medium])
                }
            }
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
        .frame(minHeight: 60)
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
