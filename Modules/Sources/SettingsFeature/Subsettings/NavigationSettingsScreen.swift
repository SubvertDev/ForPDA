//
//  NavigationSettingsScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models

@ViewAction(for: NavigationSettingsFeature.self)
public struct NavigationSettingsScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<NavigationSettingsFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<NavigationSettingsFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List {
                    Group {
                        Row(LocalizedStringResource("Topic opening", bundle: .module)) {
                            EnumPickerMenu(selection: $store.topicOpening) { strategy in
                                Text(strategy.text)
                            } label: {
                                HStack(spacing: 9) {
                                    Text(store.topicOpening.text)
                                    Image(systemSymbol: .chevronUpChevronDown)
                                }
                                .foregroundStyle(Color(.Labels.teritary))
                            }
                        }
                        
                        if isLiquidGlass {
                            Row(LocalizedStringResource("Floating navigation", bundle: .module)) {
                                Toggle(String(""), isOn: $store.floatingNavigation)
                                    .labelsHidden()
                            }
                        }
                    }
                    .tint(tintColor)
                    .listRowBackground(Color(.Background.teritary))
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .frame(minHeight: 60)
                }
                .scrollContentBackground(.hidden)
                ._contentMargins(.top, 16)
            }
            .navigationTitle(Text("Navigation", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .animation(.default, value: store.state)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row<Content: View>(_ text: LocalizedStringResource, content: () -> Content) -> some View {
        HStack(spacing: 0) {
            Text(text)
                .font(.body)
                .foregroundStyle(Color(.Labels.primary))
            
            Spacer(minLength: 8)
            
            content()
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    NavigationStack {
        NavigationSettingsScreen(store: Store(initialState: NavigationSettingsFeature.State()) {
            NavigationSettingsFeature()
        } withDependencies: { _ in
            
        })
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

