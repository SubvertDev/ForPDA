//
//  SettingsScreen.swift
//
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI
import ComposableArchitecture

public struct SettingsScreen: View {
        
    @Perception.Bindable public var store: StoreOf<SettingsFeature>
    
    public init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            List {
                Section(header: Text("General", bundle: .module)) {
                    Button {
                        store.send(.languageButtonTapped)
                    } label: {
                        HStack {
                            Text("Language", bundle: .module)
                                .foregroundStyle(Color(.label))
                            Spacer()
                            Text(store.currentLanguage)
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                }
                
                Section(header: Text("Appearance", bundle: .module)) {
                    Button {
                        store.send(.themeButtonTapped)
                    } label: {
                        HStack {
                            Text("Theme", bundle: .module)
                                .foregroundStyle(Color(.label))
                            Spacer()
                            Text("Auto", bundle: .module)
                                .foregroundStyle(Color(.systemGray))
                        }
                    }
                }
                
                Section(header: Text("Advanced", bundle: .module)) {
                    Button {
                        store.send(.safariExtensionButtonTapped)
                    } label: {
                        Text("Safari extension", bundle: .module)
                            .foregroundStyle(Color(.label))
                    }
                }
                
                Section(header: Text("About App", bundle: .module)) {
                    Text("Version \(store.appVersionAndBuild)", bundle: .module)
                    
                    Button {
                        store.send(.checkVersionsButtonTapped)
                    } label: {
                        Text("Check new versions on GitHub", bundle: .module)
                            .foregroundStyle(Color(.label))
                    }
                }
            }
            .navigationTitle(Text("Settings", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen(
            store: Store(
                initialState: SettingsFeature.State()
            ) {
                SettingsFeature()
            }
        )
    }
}
