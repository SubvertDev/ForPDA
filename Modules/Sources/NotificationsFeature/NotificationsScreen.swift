//
//  DeveloperScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

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
                        
                        Row("QMS", value: optionBinding(.qms))
                        Row("System events", value: optionBinding(.qmsSystemEvents))
                        Row("Mentions", value: optionBinding(.mentions))
                        FavoritesRow()
                    } header: {
                        Text("General", bundle: .module)
                    }
                    .tint(tintColor)
                    .listRowBackground(Color(.Background.teritary))
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    
//                    Section {
//                        Row("Background notifications", value: Binding(store.$appSettings.backgroundNotifications2))
//                    } header: {
//                        Text("Experimental", bundle: .module)
//                    }
//                    .tint(tintColor)
//                    .listRowBackground(Color(.Background.teritary))
//                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
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

    @ViewBuilder
    private func FavoritesRow() -> some View {
        HStack(spacing: 0) {
            Text("Favorites", bundle: .module)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 8)
            
            Menu {
                Picker(
                    String(),
                    selection: Binding(
                        get: { store.appSettings.notifications2.favoritesMode },
                        set: { store.send(.favoritesModeChanged($0)) }
                    )
                ) {
                    ForEach(NotificationsSettings2.FavoritesMode.allCases) { mode in
                        Text(mode.title)
                            .tag(mode)
                    }
                }
                .pickerStyle(.inline)
            } label: {
                HStack(spacing: 9) {
                    Text(store.appSettings.notifications2.favoritesMode.title)
                    Image(systemSymbol: .chevronUpChevronDown)
                }
                .foregroundStyle(Color(.Labels.teritary))
            }
        }
        .disabled(!store.areNotificationsEnabled)
        .frame(minHeight: 60)
    }

    private func optionBinding(_ option: NotificationsSettings2) -> Binding<Bool> {
        Binding(
            get: { store.appSettings.notifications2.contains(option) },
            set: { store.send(.notificationOptionChanged(option, isEnabled: $0)) }
        )
    }
}

// MARK: - Extensions

extension NotificationsSettings2.FavoritesMode {
    var title: LocalizedStringResource {
        switch self {
        case .all:
            LocalizedStringResource("All", bundle: .module)
        case .important:
            LocalizedStringResource("Only important", bundle: .module)
        case .disabled:
            LocalizedStringResource("Do not", bundle: .module)
        }
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
