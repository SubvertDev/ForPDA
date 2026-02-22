//
//  FormFormFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Feature

@Reducer
public struct FormEditorFeature: Reducer {
    
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

struct FormEditorRow: View {
    
    @Perception.Bindable var store: StoreOf<FormEditorFeature>
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
                        isEditor: true,
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

    FormEditorRow(
        store: Store(
            initialState: FormEditorFeature.State(
                id: 0,
                title: "Editor Title",
                description: "Editor Description",
                placeholder: "Editor Placeholder",
                flag: 1,
                defaultText: "Editor Default Text"
            )
        ) {
            FormEditorFeature()
        },
        focusedField: $focusedField
    )
}
