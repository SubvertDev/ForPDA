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
                        
                        if store.isUserSessionHasModerationGroup {
                            Row(
                                LocalizedStringResource("Show all posts in topic", bundle: .module),
                                description: LocalizedStringResource("When you enter a topic, the 'All posts' filter will be selected", bundle: .module)
                            ) {
                                Toggle(String(""), isOn: $store.topicShowAllPosts)
                                    .labelsHidden()
                            }
                        }
                        
                        if isLiquidGlass {
                            Row(LocalizedStringResource("Hide tabbar on scroll", bundle: .module)) {
                                Toggle(String(""), isOn: $store.hideTabBarOnScroll)
                                    .labelsHidden()
                            }
                            
                            Row(LocalizedStringResource("Floating navigation", bundle: .module)) {
                                Toggle(String(""), isOn: $store.floatingNavigation)
                                    .labelsHidden()
                            }
                            
                            Row(LocalizedStringResource("Experimental navigation", bundle: .module)) {
                                Toggle(String(""), isOn: $store.experimentalFloatingNavigation)
                                    .labelsHidden()
                            }
                            .disabled(!store.floatingNavigation)
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
            ._toolbarTitleDisplayMode(.inline)
            .animation(.default, value: store.state)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row<Content: View>(
            _ text: LocalizedStringResource,
            description: LocalizedStringResource? = nil,
            content: () -> Content
    ) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(text)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.primary))
                
                if let description {
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 12)
            
            Spacer(minLength: 8)
            
            content()
        }
        .frame(maxWidth: .infinity)
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

