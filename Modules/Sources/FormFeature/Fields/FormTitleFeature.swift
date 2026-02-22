//
//  FormTitleFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Feature

@Reducer
public struct FormTitleFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        public let id: Int
        let text: String
        let flag = 0
        
        public init(id: Int, text: String) {
            self.id = id
            self.text = text
        }
        
        var nodes: [FormNode] = []
        
        func getValue() -> String {
            return "\"\""
        }
        
        func isValid() -> Bool {
            return true
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case view(View)
        
        public enum View {
            case onAppear
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                break
                
            case .view(.onAppear):
                state.nodes = FormNodeBuilder(text: state.text).build()
            }
            return .none
        }
    }
}

// MARK: - View

@ViewAction(for: FormTitleFeature.self)
struct FormTitleRow: View {
    
    @Perception.Bindable var store: StoreOf<FormTitleFeature>
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                ForEach(store.nodes, id: \.self) { node in
                    FormNodeView(node: node)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.teritary))
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    @Previewable @FocusState var focusedField: Int?

    FormTitleRow(
        store: Store(
            initialState: FormTitleFeature.State(
                id: 0,
                text: "Title Text"
            )
        ) {
            FormTitleFeature()
        }
    )
}
