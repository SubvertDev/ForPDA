//
//  ReputationChangeView.swift
//  ForPDA
//
//  Created by Xialtal on 13.06.25.
//

import ComposableArchitecture
import SwiftUI
import SharedUI
import SFSafeSymbols

public struct ReputationChangeView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ReputationChangeFeature>
    @Environment(\.tintColor) private var tintColor
    
    @FocusState private var isFocused: Bool

    // MARK: - Init

    public init(store: StoreOf<ReputationChangeFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 0) {
                Text("For «\(store.username)»", bundle: .module)
                    .font(.subheadline)
                    .foregroundStyle(Color(.Labels.secondary))
                    .padding(.bottom, isLiquidGlass ? 20 : 25)
                    .frame(maxWidth: .infinity, alignment: isLiquidGlass ? .center : .leading)
                    .offset(y: isLiquidGlass ? -6 : 0)
                
                Section {
                    Field(
                        text: $store.changeReason.sending(\.reasonChanged),
                        description: "",
                        guideText: "",
                        isEditor: true,
                        isFocused: $isFocused
                    )
                } header: {
                    Text("Input reason", bundle: .module)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.Labels.teritary))
                }
                .padding(.bottom, 6)
                
                ActionButtons()
            }
            .padding(.horizontal, 16)
            .background {
                if !isLiquidGlass {
                    Color(.Background.primary)
                }
            }
            .onTapGesture {
                isFocused = false
            }
            .modifier(NavigationTitle())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.cancelButtonTapped)
                    } label: {
                        if isLiquidGlass {
                            Image(systemSymbol: .xmark)
                        } else {
                            Image(systemSymbol: .xmark)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(.Labels.teritary))
                                .frame(width: 30, height: 30)
                                .background(
                                    Circle()
                                        .fill(Color(.Background.quaternary))
                                        .clipShape(Circle())
                                )
                        }
                    }
                }
            }
        }
    }
    
    @available(iOS, deprecated: 26.0)
    private struct NavigationTitle: ViewModifier {
        func body(content: Content) -> some View {
            if #available(iOS 26.0, *) {
                content
                    .navigationTitle(Text("Changing reputation", bundle: .module))
                    .toolbarTitleDisplayMode(.inline)
            } else {
                content
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Text("Changing reputation", bundle: .module)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
            }
        }
    }
    
    // MARK: - Bottom Buttons
        
    private func ActionButtons() -> some View {
        HStack {
            BottomButton(title: "Down", image: .arrowshapeDown) {
                store.send(.downButtonTapped)
            }
            
            BottomButton(title: "Up", image: .arrowshapeUp) {
                store.send(.upButtonTapped)
            }
        }
        .padding(.vertical, 8)
        .opacity(store.changeReason.isEmpty ? 0.3 : 1)
        .disabled(store.changeReason.isEmpty)
        .animation(.default, value: store.changeReason.isEmpty)
    }
    
    // MARK: - Bottom Button
    
    @ViewBuilder
    private func BottomButton(
        title: LocalizedStringKey,
        image: SharedUIImages,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Label {
                Text(title, bundle: .module)
            } icon: {
                Image(image)
            }
            .foregroundStyle(tintColor)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .padding(8)
        }
        .background {
            if isLiquidGlass {
                Capsule()
                    .fill(tintColor.opacity(0.12))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(tintColor.opacity(0.12))
            }
        }
        .liquidIfAvailable(glass: .identity, isInteractive: !store.changeReason.isEmpty)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    @Previewable @State var showSheet = true
    
    return Rectangle()
        .fill(.white)
        .ignoresSafeArea()
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                ReputationChangeView(
                    store: Store(
                        initialState: ReputationChangeFeature.State(
                            userId: 6176341,
                            username: "AirFlare",
                            content: .post(id: 0)
                        )
                    ) {
                        ReputationChangeFeature()
                    }
                )
            }
            .presentationDetents([.height(360)])
        }
        .environment(\.tintColor, Color(.Theme.primary))
        .tint(Color(.Theme.primary))
}
