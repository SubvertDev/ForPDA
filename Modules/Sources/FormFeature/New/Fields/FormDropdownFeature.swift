//
//  FormDropdownFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Feature

@Reducer
public struct FormDropdownFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        public let id: Int
        let title: String
        let description: String
        let flag: Int
        let options: [String]
        public var selectedOption: String
        
        public init(
            id: Int,
            title: String,
            description: String,
            flag: Int,
            options: [String]
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.flag = flag
            self.options = options
            self.selectedOption = options.first ?? ""
        }
        
        func getValue() -> String {
            return selectedOption
        }
        
        func isValid() -> Bool {
            return !selectedOption.isEmpty
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case view(View)
        
        public enum View {
            case menuOptionSelected(String)
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
            switch action {
            case .binding:
                break
                
            case let .view(.menuOptionSelected(selectedOption)):
                state.selectedOption = selectedOption
            }
            return .none
        }
    }
}

// MARK: - View

@ViewAction(for: FormDropdownFeature.self)
struct FormDropdownRow: View {
    
    @Perception.Bindable var store: StoreOf<FormDropdownFeature>
    @Environment(\.tintColor) private var tintColor
    
    var body: some View {
        WithPerceptionTracking {
            FieldSection(
                title: store.title,
                description: store.description,
                required: store.isRequired
            ) {
                WithPerceptionTracking {
                    Menu {
                        ForEach(store.options, id: \.self) { option in
                            Button {
                                send(.menuOptionSelected(option))
                            } label: {
                                Text(option)
                            }
                        }
                    } label: {
                        HStack {
                            Text(store.selectedOption)
                                .font(.body)
                                .lineLimit(1)
                                .foregroundStyle(Color(.Labels.primary))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Image(systemSymbol: .chevronUpChevronDown)
                                .tint(tintColor)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.Background.teritary))
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color(.Separator.primary))
                        }
                    }
                    .listRowBackground(Color(.Background.teritary))
                }
            }
        }
    }
}

// MARK: - Previews

#Preview {
    FormDropdownRow(
        store: Store(
            initialState: FormDropdownFeature.State(
                id: 0,
                title: "Update type",
                description: "What do we publish?",
                flag: 1,
                options: ["New version", "Beta", "Modification", "Other"]
            )
        ) {
            FormDropdownFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}
