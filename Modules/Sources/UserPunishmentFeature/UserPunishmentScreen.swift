//
//  UserPunishmentScreen.swift
//  ForPDA
//
//  Created by Xialtal on 28.06.26.
//

import SwiftUI
import ComposableArchitecture
import Models
import SharedUI
import SFSafeSymbols

@ViewAction(for: UserPunishmentFeature.self)
public struct UserPunishmentScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<UserPunishmentFeature>
    @FocusState private var focus: UserPunishmentFeature.State.Field?
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<UserPunishmentFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView(.vertical) {
                if !store.categories.isEmpty {
                    Content()
                }
            }
            .scrollIndicators(.hidden)
            .navigationTitle(Text("Punishment", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .alert($store.scope(\.alert, action: \.alert))
            .safeAreaInset(edge: .bottom) {
                ApplyButton()
            }
            .onTapGesture {
                focus = nil
            }
            .overlay {
                if store.categories.isEmpty {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        send(.cancelButtonTapped)
                    } label: {
                        if isLiquidGlass {
                            Image(systemSymbol: .xmark)
                        } else {
                            Text("Cancel", bundle: .module)
                        }
                    }
                    .tint(tintColor)
                    .disabled(store.isSending)
                }
            }
            .background(Color(.Background.primary))
            .disabled(store.isSending)
            .animation(.default, value: store.isSending)
            .bind($store.focus, to: $focus)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private func Content() -> some View {
        WithPerceptionTracking {
            VStack(spacing: 28) {
                CategoriesPicker(store.categories)
                
                if let category = store.categories[id: store.currentCategory.id] {
                    TemplatesPicker(category.templates)
                    
                    if category.supportsRestrictions {
                        PremoderationRestriction()
                        
                        ReadOnlyRestriction()
                        
                        BanRestriction()
                    }
                    
                    if case .post = store.target {
                        DeletePostToggle(
                            value: $store.currentCategory.template.flag.options(.deletePost)
                        )
                    }
                    
                    Field(
                        title: "Reason",
                        content: $store.currentCategory.template.reason,
                        placeholder: LocalizedStringResource("Input reason...", bundle: .module),
                        focusEqual: .reason
                    )
                    
                    Field(
                        title: "Message",
                        content: $store.currentCategory.template.message,
                        placeholder: LocalizedStringResource("Input message...", bundle: .module),
                        focusEqual: .message
                    )
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Categories Picker
    
    @ViewBuilder
    private func CategoriesPicker(_ categories: IdentifiedArrayOf<UserPunishmentCategory>) -> some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                Header(title: "Levels")
                
                Menu {
                    ForEach(categories, id: \.id) { category in
                        Button {
                            send(.updateCategory(id: category.id))
                        } label: {
                            Text(verbatim: category.title)
                        }
                    }
                } label: {
                    PickerHeader(title: store.currentCategory.title)
                }
            }
        }
    }
    
    // MARK: - Templates Picker
    
    @ViewBuilder
    private func TemplatesPicker(_ templates: [UserPunishmentTemplate]) -> some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                Header(title: "Templates")
                
                Menu {
                    ForEach(templates, id: \.id) { template in
                        Button {
                            send(.updateTemplate(id: template.id))
                        } label: {
                            Text(verbatim: template.title)
                        }
                    }
                } label: {
                    PickerHeader(title: store.currentCategory.template.title)
                }
            }
        }
    }
    
    // MARK: - Premoderation Restriction
    
    @ViewBuilder
    private func PremoderationRestriction() -> some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                Header(title: "Premoderation")
                
                HStack(spacing: 8) {
                    Field(
                        type: .singleLine(numeric: true),
                        content: Binding(get: {
                            String(store.currentCategory.template.premoderationHours)
                        }, set: { newValue in
                            send(.updateTemplatePremodValue(newValue))
                        }),
                        placeholder: LocalizedStringResource(stringLiteral: String(store.currentCategory.template.premoderationHours)),
                        focusEqual: .premod,
                        characterLimit: 7
                    )
                    .frame(maxWidth: 120)
                    
                    DateTypePicker(
                        for: $store.premodDateFormat,
                        title: store.premodDateFormat.title
                    )
                    
                    HStack(spacing: 0) {
                        Header(title: "Always")
                            .padding(.trailing, 8)
                        
                        Toggle(String(""), isOn: $store.currentCategory.template.flag.options(.alwaysPremod))
                            .labelsHidden()
                            .tint(tintColor)
                        
                    }
                }
            }
        }
    }
    
    // MARK: - Read Only Restriction
    
    @ViewBuilder
    private func ReadOnlyRestriction() -> some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                Header(title: "Read Only")
                
                HStack(spacing: 8) {
                    Field(
                        type: .singleLine(numeric: true),
                        content: Binding(get: {
                            String(store.currentCategory.template.readOnlyHours)
                        }, set: { newValue in
                            send(.updateTemplateReadOnlyValue(newValue))
                        }),
                        placeholder: LocalizedStringResource(stringLiteral: String(store.currentCategory.template.readOnlyHours)),
                        focusEqual: .readOnly,
                        characterLimit: 7
                    )
                    .frame(width: 120)
                    
                    DateTypePicker(
                        for: $store.readOnlyDateFormat,
                        title: store.readOnlyDateFormat.title
                    )
                }
            }
        }
    }
    
    // MARK: - Ban Restriction
    
    @ViewBuilder
    private func BanRestriction() -> some View {
        VStack(spacing: 6) {
            Header(title: "Ban")
            
            Menu {
                Picker(selection: $store.banType, label: EmptyView()) {
                    Text("No", bundle: .module)
                        .tag(UserPunishmentFeature.BanTypePicker.no)
                    
                    Text("Permanent", bundle: .module)
                        .tag(UserPunishmentFeature.BanTypePicker.permanent)
                    
                    Text("Last chanse", bundle: .module)
                        .tag(UserPunishmentFeature.BanTypePicker.lastChanse)
                }
            } label: {
                PickerHeader(title: store.banType.title)
            }
        }
    }
    
    // MARK: - Date Type Picker
    
    @ViewBuilder
    private func DateTypePicker<SelectionValue: Hashable>(
        for value: Binding<SelectionValue>,
        title: String
    ) -> some View {
        Menu {
            Picker(selection: value, label: EmptyView()) {
                Text("Days", bundle: .module)
                    .tag(UserPunishmentFeature.DateFormatPicker.days)
                
                Text("Hours", bundle: .module)
                    .tag(UserPunishmentFeature.DateFormatPicker.hours)
            }
        } label: {
            PickerHeader(title: title)
        }
    }
    
    // MARK: - Delete Post Toggle
    
    @ViewBuilder
    private func DeletePostToggle(value: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Header(title: "Delete Post")
            
            Toggle(String(""), isOn: value)
                .labelsHidden()
                .tint(tintColor)
        }
    }
    
    // MARK: - Apply Button
    
    @ViewBuilder
    private func ApplyButton() -> some View {
        WithPerceptionTracking {
            Button {
                send(.applyButtonTapped)
            } label: {
                if store.isSending {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                } else {
                    Text("Apply", bundle: .module)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(tintColor)
            .disabled(store.isApplyButtonDisabled)
            .frame(height: 48)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color(.Background.primary))
        }
    }
    
    // MARK: - Field
    
    enum FieldType {
        case singleLine(numeric: Bool)
        case full
    }
    
    private func Field<Action: View>(
        type: FieldType = .full,
        title: LocalizedStringKey? = nil,
        content: Binding<String>,
        placeholder: LocalizedStringResource,
        focusEqual: UserPunishmentFeature.State.Field,
        characterLimit: Int? = nil,
        @ViewBuilder bbPanel: @escaping () -> Action = { EmptyView() }
    ) -> some View {
        VStack(spacing: 6) {
            if let title = title {
                Header(title: title)
            }
            
            HStack {
                switch type {
                case .singleLine(let numeric):
                    SharedUI.SingleLineField(
                        content: content,
                        placeholder: placeholder,
                        focusEqual: focusEqual,
                        focus: $focus,
                        keyboardType: numeric ? .numberPad : .default,
                        characterLimit: characterLimit
                    )
                case .full:
                    SharedUI.Field(
                        content: content,
                        placeholder: placeholder,
                        focusEqual: focusEqual,
                        focus: $focus,
                        characterLimit: characterLimit,
                        minHeight: 144,
                        bbPanel: bbPanel
                    )
                }
            }
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
    
    private func PickerHeader(title: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color(.Labels.primary))
                .padding(.leading, 16)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Image(systemSymbol: .chevronUpChevronDown)
                .foregroundStyle(Color(.Labels.teritary))
                .padding(.trailing, 11)
        }
        .frame(minHeight: 60)
        .background(Color(.Background.teritary))
        .cornerRadius(isLiquidGlass ? 28 : 14)
    }
}

// MARK: - Extensions

extension Binding where Value == UserPunishmentTemplateFlag {
    func options(_ options: Value) -> Binding<Bool> {
        return .init { () -> Bool in
            wrappedValue.contains(options)
        } set: { newValue in
            if newValue {
                wrappedValue.insert(options)
            } else {
                wrappedValue.remove(options)
            }
        }
    }
}

fileprivate extension UserPunishmentFeature.DateFormatPicker {
    var title: String {
        return switch self {
        case .days:  String(localized: "Days", bundle: .module)
        case .hours: String(localized: "Hours", bundle: .module)
        }
    }
}

fileprivate extension UserPunishmentFeature.BanTypePicker {
    var title: String {
        return switch self {
        case .no:         String(localized: "No", bundle: .module)
        case .permanent:  String(localized: "Permanent", bundle: .module)
        case .lastChanse: String(localized: "Last chanse", bundle: .module)
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        UserPunishmentScreen(
            store: Store(
                initialState: UserPunishmentFeature.State(
                    userId: 6176341,
                    target: .post(id: 123456)
                )
            ) {
                UserPunishmentFeature()
            }
        )
    }
}

#Preview("Punishment Apply Confirmation") {
    NavigationStack {
        UserPunishmentScreen(
            store: Store(
                initialState: UserPunishmentFeature.State(
                    userId: 6176341,
                    target: .post(id: 123456)
                )
            ) {
                UserPunishmentFeature()
            } withDependencies: {
                $0.apiClient.applyUserPunishment = { _ in
                    try await Task.sleep(for: .seconds(1))
                    return .needConfirmation
                }
            }
        )
    }
}
