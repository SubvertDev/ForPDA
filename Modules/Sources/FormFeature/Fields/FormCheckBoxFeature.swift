//
//  FormCheckBoxFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

#warning("todo")

import SwiftUI
import ComposableArchitecture

// MARK: - Feature

@Reducer
public struct FormCheckBoxFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        public let id: Int
        let flag: Int
        
        func getValue() -> String {
            return ""
        }
        
        func isValid() -> Bool {
            return true
        }
    }
    
    // MARK: - Actions
    
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

struct FormCheckBoxRow: View {
    
    @Perception.Bindable var store: StoreOf<FormCheckBoxFeature>
    
    var body: some View {
        Text(verbatim: "CheckBox")
    }
}
