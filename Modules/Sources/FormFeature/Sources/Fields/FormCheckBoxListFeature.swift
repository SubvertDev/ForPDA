//
//  FormCheckBoxFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture
import Models

// MARK: - Feature

@Reducer
public struct FormCheckBoxListFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        public let id: Int
        let title: String
        let description: String
        let flag: FormFieldFlag
        let options: [String]
        
        var selectedOptions: [Int: Bool]
        
        public init(
            id: Int,
            title: String,
            description: String,
            flag: FormFieldFlag,
            options: [String]
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.flag = flag
            self.options = options
            
            self.selectedOptions = [0: false]
        }
        
        func getValue() -> FormValue {
            return .array(selectedOptions
                .filter { $0.value == true }
                .map { .integer($0.key + 1) })
        }
        
        func isValid() -> Bool {
            return isRequired
            ? !selectedOptions.filter { $0.value == true }.isEmpty
            : true
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case view(View)
        
        public enum View {
            case checkboxClicked(Int, Bool)
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                break
                
            case let .view(.checkboxClicked(id, isSelected)):
                state.selectedOptions[id] = isSelected
            }
            return .none
        }
    }
}

// MARK: - View

@ViewAction(for: FormCheckBoxListFeature.self)
struct FormCheckBoxListRow: View {
    
    @Perception.Bindable var store: StoreOf<FormCheckBoxListFeature>
    @Environment(\.tintColor) private var tintColor
    
    @State var isChecked = false
    
    var body: some View {
        WithPerceptionTracking {
            FieldSection(
                title: store.title,
                description: store.description,
                required: store.isRequired
            ) {
                VStack(spacing: 6) {
                    ForEach(store.options.indices, id: \.hashValue) { index in
                        WithPerceptionTracking {
                            Toggle(isOn: Binding(get: {
                                store.selectedOptions[index] ?? false
                            }, set: { value in
                                send(.checkboxClicked(index, value))
                            })) {
                                Text(store.options[index])
                                    .font(.subheadline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .toggleStyle(CheckBox())
                            .padding(6)
                        }
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.Background.teritary))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    FormCheckBoxListRow(
        store: Store(
            initialState: FormCheckBoxListFeature.State(
                id: 0,
                title: "Select answer",
                description: "This is checkbox list description...",
                flag: .required,
                options: ["Yes", "No"]
            )
        ) {
            FormCheckBoxListFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}
