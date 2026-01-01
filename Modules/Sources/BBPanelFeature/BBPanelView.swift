//
//  BBPanelView.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI

@ViewAction(for: BBPanelFeature.self)
public struct BBPanelView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<BBPanelFeature>
    @Environment(\.tintColor) private var tintColor
    
    @State private var selectedColor: Color = .clear
    
    // MARK: - Init
    
    public init(store: StoreOf<BBPanelFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            if #available(iOS 26.0, *) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(store.tags, id: \.self) { tag in
                            Button {
                                send(.tagButtonTapped(tag))
                            } label: {
                                Image(systemSymbol: tag.icon)
                                    .foregroundStyle(Color(.Labels.primary))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 12)
                }
                .sheet(isPresented: Binding($store.destination.smileTag)) {
                    SmilesList()
                }
                .sheet(isPresented: Binding($store.destination.colorTag)) {
                    ColorPickerView(onColorSelected: { color in
                        if let color = color.hexColor {
                            send(.colorSelected(color))
                        }
                    })
                    .presentationDetents([.medium])
                }
                .alert(
                    BBPanelFeature.Localization.inputFullUrl,
                    isPresented: Binding($store.destination.urlTag)
                ) {
                    AlertInput({
                        send(.alertTagButtonTapped(.url))
                    })
                }
                .alert(
                    BBPanelFeature.Localization.inputSpoilerTitle,
                    isPresented: Binding($store.destination.spoilerWithTitleTag)
                ) {
                    AlertInput({
                        send(.alertTagButtonTapped(.spoilerWithTitle))
                    })
                }
                .background(.bar.opacity(0.5), in: .capsule)
                .glassEffect()
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                .onAppear {
                    send(.onAppear)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        Button {
                            
                        } label: {
                            Image(systemSymbol: .plusAppFill)
                                .foregroundStyle(Color(.Labels.primary))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 12)
                    .border(Color(.red/*Background.secondary*/))
                    .background(Color(.Background.secondary))
                }
            }
        }
    }
    
    @ViewBuilder
    private func AlertInput(_ action: @escaping () -> Void) -> some View {
        TextField(String(), text: $store.alertInput)
        
        Button(LocalizedStringResource("Cancel", bundle: .module)) { }
        
        Button(LocalizedStringResource("OK", bundle: .module)) {
            action()
        }
        .disabled(store.alertInput.isEmpty)
    }
    
    @ViewBuilder
    private func SmilesList() -> some View {
        Grid {
            GridRow {
                Text("Sheet")
                Text("Sheet")
                Text("Sheet")
            }
            
            GridRow {
                Text("Sheet")
                Text("Sheet")
                Text("Sheet")
            }
            
            GridRow {
                Text("Sheet")
                Text("Sheet")
                Text("Sheet")
            }
            
            GridRow {
                Text("Sheet")
                Text("Sheet")
                Text("Sheet")
            }
            
            GridRow {
                Text("Sheet")
                Text("Sheet")
                Text("Sheet")
            }
        }
        .presentationDetents([.height(337)])
        .presentationDragIndicator(.visible)
        
    }
}

// MARK: - Helpers

extension Color {
    var hexColor: String? {
        let components = self.cgColor?.components
        guard let r = components?[0], let g = components?[1], let b = components?[2] else {
            return nil
        }
        return String(format: "#%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// MARK: - Previews

#Preview {
    BBPanelView(
        store: Store(
            initialState: BBPanelFeature.State(
                with: .qms
            ),
        ) {
            BBPanelFeature()
        }
    )
}
