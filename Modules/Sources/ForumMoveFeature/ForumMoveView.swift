//
//  ForumMoveView.swift
//  ForPDA
//
//  Created by Xialtal on 11.04.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI

@ViewAction(for: ForumMoveFeature.self)
public struct ForumMoveView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ForumMoveFeature>
    @Environment(\.tintColor) private var tintColor
    
    @FocusState private var focus: ForumMoveFeature.State.Field?
    
    // MARK: - Init
    
    public init(store: StoreOf<ForumMoveFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 0) {
                InputField()
                    .padding(.bottom, 28)
                    
                if case .topic = store.type {
                    Row("Save link", value: $store.isSaveLinkForTopic)
                        .padding(.bottom, 64)
                }
                
                ActionButtons()
            }
            .padding(.horizontal, 16)
            .background {
                if !isLiquidGlass {
                    Color(.Background.primary)
                }
            }
            ._toolbarTitleDisplayMode(.inline)
            .modifier(NavigationTitle(title: navigationTitleText()))
            .toolbar {
                ToolbarItem(placement: isLiquidGlass ? .topBarLeading : .topBarTrailing) {
                    Button {
                        send(.cancelButtonTapped)
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
                    .disabled(store.isSending)
                }
            }
            .bind($store.focus, to: $focus)
            .onTapGesture {
                focus = nil
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    @available(iOS, deprecated: 26.0)
    private struct NavigationTitle: ViewModifier {
        let title: LocalizedStringKey
        
        func body(content: Content) -> some View {
            if isLiquidGlass {
                content
                    .navigationTitle(Text(title, bundle: .module))
            } else {
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Text(title, bundle: .module)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
            }
        }
    }
    
    // MARK: - Input Field
    
    private func InputField() -> some View {
        VStack(spacing: 6) {
            let header = switch store.type {
            case .topic: "Enter the forum link"
            case .posts: "Enter the topic link"
            }
            Header(title: LocalizedStringKey(header))
            
            Field(
                content: $store.inputUrl,
                placeholder: LocalizedStringResource("Enter...", bundle: .module),
                focusEqual: ForumMoveFeature.State.Field.url,
                focus: $focus
            )
            
            if let error = store.error {
                Text(error.title, bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color(.Main.red))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
            }
        }
        .animation(.default, value: store.error)
        .onChange(of: store.inputUrl) { _ in
            if store.error != nil {
                send(.unlockMoveButton)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    @ViewBuilder
    private func ActionButtons() -> some View {
        HStack {
            Button {
                send(.cancelButtonTapped)
            } label: {
                Text("Cancel", bundle: .module)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
            .buttonStyle(.bordered)
            .disabled(store.isSending)
            .frame(height: 48)

            Button {
               send(.moveButtonTapped)
            } label: {
                if store.isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                } else {
                    Text("Move", bundle: .module)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isSending || store.isMoveButtonDisabled)
            .frame(height: 48)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(_ title: LocalizedStringKey, value: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Text(title, bundle: .module)
                .foregroundStyle(Color(.Labels.teritary))
                .font(.subheadline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle(String(""), isOn: value)
                .labelsHidden()
        }
    }

    // MARK: - Header
    
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Helpers
    
    private func navigationTitleText() -> LocalizedStringKey {
        return switch store.type {
        case .posts: "Move Posts"
        case .topic: "Move Topic"
        }
    }
}

// MARK: - Extensions

private extension ForumMoveFeature.URLValidationErrorReason {
    var title: LocalizedStringKey {
        switch self {
        case .badURL: "Incorrect URL"
        case .needTopicUrl: "Entered URL is not topic URL"
        case .needForumUrl: "Entered URL is not forum URL"
        case .unableToExtractTopicId: "Unable to extract topic id from URL"
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ForumMoveView(
            store: Store(
                initialState: ForumMoveFeature.State(
                    type: .topic(1)
                )
            ) {
                ForumMoveFeature()
            }
        )
    }
}
