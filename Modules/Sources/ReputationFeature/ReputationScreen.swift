//
//  ReputationScreen.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 11.07.2025.
//
import Foundation
import SwiftUI
import ComposableArchitecture
import SharedUI

@ViewAction(for: ReputationFeature.self)
public struct ReputationScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ReputationFeature>
    
    public init(store: StoreOf<ReputationFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                VStack {
                    SegmentPicker()
                    if !store.isLoading {
                        switch store.pickerSelection {
                        case .history:
                            HistorySelection()
                                .onAppear {
                                    send(.onAppear)
                                }
                        case .votes:
                            Text("vot")
                                .onAppear {
                                    send(.onAppear)
                                }
                        }
                    } else {
                        Spacer()
                        PDALoader()
                            .frame(width: 24, height: 24)
                        Spacer()
                    }
                }
            }
            .navigationTitle(Text("Reputation", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func HistorySelection() -> some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
            
        }
    }
    
    // MARK: - SegmentPicker
    
    @ViewBuilder
    private func SegmentPicker() -> some View {
        _Picker("", selection: $store.pickerSelection) {
            Text("History", bundle: .module)
                .tag(ReputationFeature.PickerSelection.history)
            
            Text("Votes", bundle: .module)
                .tag(ReputationFeature.PickerSelection.votes)
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Perception Picker
// https://github.com/pointfreeco/swift-perception/issues/100

struct _Picker<Label, SelectionValue, Content>: View
where Label: View, SelectionValue: Hashable, Content: View {
    let label: Label
    let content: Content
    let selection: Binding<SelectionValue>
    
    init(
        _ titleKey: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) where Label == Text {
        self.label = Text(titleKey)
        self.content = content()
        self.selection = selection
    }
    
    var body: some View {
        _PerceptionLocals.$skipPerceptionChecking.withValue(true) {
            Picker(selection: selection, content: { content }, label: { label })
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReputationScreen(
            store: Store(
                initialState: ReputationFeature.State()
            ) {
                ReputationFeature()
            }
        )
    }
}
