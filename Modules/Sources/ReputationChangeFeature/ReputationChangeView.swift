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
        _GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                BottomButton(title: "Down", image: .arrowshapeDown) {
                    store.send(.downButtonTapped)
                }
                
                BottomButton(title: "Up", image: .arrowshapeUp) {
                    store.send(.upButtonTapped)
                }
            }
        }
        .padding(.vertical, 8)
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
            WithPerceptionTracking {
                Label {
                    Text(title, bundle: .module)
                } icon: {
                    Image(image)
                }
                .foregroundStyle(store.changeReason.isEmpty ? .secondary : tintColor)
                .frame(maxWidth: .infinity)
                .padding(8)
                .if(!isLiquidGlass) { content in
                    content
                        .animation(.default, value: store.changeReason.isEmpty)
                }
            }
        }
        .ifElse(
            isLiquidGlass,
            trueCondition: { content in
                content
                    ._buttonStyleGlass(isProminent: true)
            },
            falseCondition: { content in
                content
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle)
            }
        )
        .tint(tintColor.opacity(0.12))
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    // Fitted sheet doesn't work reliably in preview macro
    PreviewView()
}

struct PreviewView: View {
    @State var store: StoreOf<ReputationChangeFeature>? = Store(
        initialState: ReputationChangeFeature.State(
            userId: 6176341,
            username: "AirFlare",
            content: .post(id: 0)
        ), reducer: {
            ReputationChangeFeature()
        }
    )
    
    var body: some View {
        VStack {
            Button(String("Open Sheet")) {
                store = Store(
                    initialState: ReputationChangeFeature.State(
                        userId: 6176341,
                        username: "AirFlare",
                        content: .post(id: 0)
                    ), reducer: {
                        ReputationChangeFeature()
                    }
                )
            }
        }
        .fittedSheet(
            item: $store,
            embedIntoNavStack: true,
            onDismiss: {},
            content: { store in
                ReputationChangeView(store: store)
            }
        )
        .environment(\.tintColor, Color(.Theme.primary))
        .tint(Color(.Theme.primary))
    }
}
