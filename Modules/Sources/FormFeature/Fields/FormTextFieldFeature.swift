//
//  FormTextFieldFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Feature

@Reducer
public struct FormTextFieldFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        public let id: Int
        let title: String
        let description: String
        let placeholder: String
        let flag: Int
        public var text = ""
        
        public init(
            id: Int,
            title: String = "",
            description: String = "",
            placeholder: String = "",
            flag: Int,
            defaultText: String = ""
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.placeholder = placeholder
            self.flag = flag
            self.text = defaultText
        }
        
        func getValue() -> String {
            return text
        }
        
        func isValid() -> Bool {
            return !text.isEmpty
        }
    }
    
    // MARK: - Action
    
    public enum Action: BindableAction {
        case binding(BindingAction<State>)
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            return .none
        }
    }
}

// MARK: - View

struct FormTextFieldRow: View {
    
    @Perception.Bindable var store: StoreOf<FormTextFieldFeature>
    @FocusState.Binding var focusedField: Int?
    
    var body: some View {
        WithPerceptionTracking {
            FieldSection(
                title: store.title,
                description: store.description,
                required: store.isRequired
            ) {
                WithPerceptionTracking {
                    Field(
                        id: store.id,
                        text: $store.text,
                        placeholder: store.placeholder,
                        isEditor: false,
                        focusedField: $focusedField
                    )
                }
            }
        }
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    @Previewable @FocusState var focusedField: Int?

    FormTextFieldRow(
        store: Store(
            initialState: FormTextFieldFeature.State(
                id: 0,
                title: "TextField Title",
                description: "TextField Description",
                placeholder: "TextField Placeholder",
                flag: 1,
                defaultText: "TextField Default Text"
            )
        ) {
            FormTextFieldFeature()
        },
        focusedField: $focusedField
    )
}
