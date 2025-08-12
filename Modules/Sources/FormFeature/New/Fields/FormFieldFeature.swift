//
//  FormFieldFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture

@Reducer
public struct FormFieldFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public enum State: Equatable, Identifiable, FormFieldConformable {
        var flag: Int { return -1 }
        
        case checkBox(FormCheckBoxFeature.State)
        case dropdown(FormDropdownFeature.State)
        case editor(FormEditorFeature.State)
        case textField(FormTextFieldFeature.State)
        case title(FormTitleFeature.State)
        case uploadBox(FormUploadBoxFeature.State)
        
        public var id: Int {
            switch self {
            case .checkBox(let state): return state.id
            case .dropdown(let state): return state.id
            case .editor(let state): return state.id
            case .textField(let state): return state.id
            case .title(let state): return state.id
            case .uploadBox(let state): return state.id
            }
        }
        
        func getValue() -> String {
            switch self {
            case .checkBox(let state): state.getValue()
            case .dropdown(let state): state.getValue()
            case .editor(let state): state.getValue()
            case .textField(let state): state.getValue()
            case .title(let state): state.getValue()
            case .uploadBox(let state): state.getValue()
            }
        }
        
        func isValid() -> Bool {
            switch self {
            case .checkBox(let state): state.isValid()
            case .dropdown(let state): state.isValid()
            case .editor(let state): state.isValid()
            case .textField(let state): state.isValid()
            case .title(let state): state.isValid()
            case .uploadBox(let state): state.isValid()
            }
        }
        
        func isRequired() -> Bool {
            switch self {
            case .checkBox(let state): state.isRequired
            case .dropdown(let state): state.isRequired
            case .editor(let state): state.isRequired
            case .textField(let state): state.isRequired
            case .title(let state): state.isRequired
            case .uploadBox(let state): state.isRequired
            }
        }
    }
    
    // MARK: - Actions
    
    public enum Action {
        case checkBox(FormCheckBoxFeature.Action)
        case dropdown(FormDropdownFeature.Action)
        case editor(FormEditorFeature.Action)
        case textField(FormTextFieldFeature.Action)
        case title(FormTitleFeature.Action)
        case uploadBox(FormUploadBoxFeature.Action)
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Scope(state: \.checkBox, action: \.checkBox) {
            FormCheckBoxFeature()
        }
        Scope(state: \.dropdown, action: \.dropdown) {
            FormDropdownFeature()
        }
        Scope(state: \.editor, action: \.editor) {
            FormEditorFeature()
        }
        Scope(state: \.textField, action: \.textField) {
            FormTextFieldFeature()
        }
        Scope(state: \.title, action: \.title) {
            FormTitleFeature()
        }
        Scope(state: \.uploadBox, action: \.uploadBox) {
            FormUploadBoxFeature()
        }
        Reduce<State, Action> { state, action in
            return .none
        }
    }
}

// MARK: - Form Field Row

struct FormFieldRow: View {
    
    @Perception.Bindable var store: StoreOf<FormFieldFeature>
    @FocusState.Binding var focusedField: Int?
    
    var body: some View {
        switch store.state {
        case .checkBox:
            if let store = store.scope(state: \.checkBox, action: \.checkBox) {
                FormCheckBoxRow(store: store)
            }
            
        case .dropdown:
            if let store = store.scope(state: \.dropdown, action: \.dropdown) {
                FormDropdownRow(store: store)
            }
            
        case .editor:
            if let store = store.scope(state: \.editor, action: \.editor) {
                FormEditorRow(store: store, focusedField: $focusedField)
            }
            
        case .textField:
            if let store = store.scope(state: \.textField, action: \.textField) {
                FormTextFieldRow(store: store, focusedField: $focusedField)
            }
            
        case .title:
            if let store = store.scope(state: \.title, action: \.title) {
                FormTitleRow(store: store)
            }
        
        case .uploadBox:
            if let store = store.scope(state: \.uploadBox, action: \.uploadBox) {
                FormUploadBoxRow(store: store)
            }
        }
    }
}

// MARK: - Form Field Header

struct FieldSection<Content: View>: View {
    
    let title: String
    let description: String
    let required: Bool
    let content: () -> Content
    
    init(
        title: String,
        description: String,
        required: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.description = description
        self.required = required
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if !title.isEmpty {
                Text(title)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.Labels.teritary))
                    .textCase(nil)
                    .overlay(alignment: .bottomTrailing) {
                        if required {
                            Text(verbatim: "*")
                                .font(.headline)
                                .offset(x: 8)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            content()
            
            if !description.isEmpty {
                let nodes = FormNodeBuilder(text: description).build(isDescription: true)
                ForEach(nodes, id: \.self) { node in
                    FormNodeView(node: node)
                }
                .padding(.leading, 16)
            }
        }
    }
}
