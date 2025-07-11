//
//  ReputationChangeView.swift
//  ForPDA
//
//  Created by Xialtal on 13.06.25.
//

import ComposableArchitecture
import SwiftUI
import SharedUI

public struct ReputationChangeView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ReputationChangeFeature>
    @Environment(\.tintColor) private var tintColor
    
    @FocusState private var isFocused: Bool

    // MARK: - Init

    public init(store: StoreOf<ReputationChangeFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 0) {
                Title()
                
                Text("For «\(store.username)»", bundle: .module)
                    .font(.subheadline)
                    .foregroundStyle(Color(.Labels.secondary))
                    .padding(.bottom, 22)
                
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
            .background(Color(.Background.primary))
            .onTapGesture {
                isFocused = false
            }
        }
    }
    
    // MARK: - Sheet Title
    
    private func Title() -> some View {
        HStack {
            Text("Changing reputation", bundle: .module)
                .font(.title3)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            Button {
                store.send(.cancelButtonTapped)
            } label: {
                Image(systemSymbol: .xmark)
                    .font(.body)
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
    
    // MARK: - Action Buttons
    
    private func ActionButtons() -> some View {
        HStack {
            Button {
                store.send(.downButtonTapped)
            } label: {
                Label {
                    Text("Down", bundle: .module)
                } icon: {
                    Image(.arrowshapeDown)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
            }
            .buttonStyle(.bordered)
            .frame(height: 48)
            
            Button {
                store.send(.upButtonTapped)
            } label: {
                Label {
                    Text("Up", bundle: .module)
                } icon: {
                    Image(.arrowshapeUp)
                }
                .frame(maxWidth: .infinity)
                .padding(8)
            }
            .buttonStyle(.bordered)
            .frame(height: 48)
        }
        .padding(.vertical, 8)
        .disabled(store.changeReason.isEmpty)
    }
}

// MARK: - Previews

#Preview {
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
    .environment(\.tintColor, Color(.Theme.primary))
    .tint(Color(.Theme.primary))
}
