//
//  FormFormFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models
import BBPanelFeature

// MARK: - Feature

@Reducer
public struct FormEditorFeature: Reducer {
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        
        var bbPanel: BBPanelFeature.State
        
        public let id: Int
        let title: String
        let description: String
        let placeholder: String
        let flag: FormFieldFlag
        let uploadBox: FormStickedUploadBox?
        public var text = ""
        public var textRange: NSRange? = nil
        
        var focus: Int? = nil
        
        public init(
            id: Int,
            title: String = "",
            description: String = "",
            placeholder: String = "",
            flag: FormFieldFlag,
            defaultText: String = "",
            uploadBox: FormStickedUploadBox? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.placeholder = placeholder
            self.flag = flag
            self.text = defaultText
            self.uploadBox = uploadBox
            
            self.bbPanel = BBPanelFeature.State(
                for: .post(isCurator: false, canModerate: false),
                supportsUpload: flag.contains(.uploadable)
            )
        }
        
        func getValue() -> FormValue {
            return .string(text)
        }
        
        func getAttachments() -> [Int] {
            var attachments: [Int] = []
            for file in bbPanel.existsFiles {
                if let serverId = file.serverId {
                    attachments.append(serverId)
                }
            }
            return attachments
        }
        
        func isValid() -> Bool {
            let isTextValid = !isRequired || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let isAttachmentValid = uploadBox?.requiresAttachment != true || !getAttachments().isEmpty
            return isTextValid && isAttachmentValid
        }
    }
    
    // MARK: - Action
    
    public enum Action: ViewAction, BindableAction {
        case binding(BindingAction<State>)
        case bbPanel(BBPanelFeature.Action)
        
        case view(View)
        public enum View {
            case onAppear
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Scope(\.bbPanel, action: \.bbPanel) {
            BBPanelFeature()
        }
        
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.onAppear):
                if !state.text.isEmpty {
                    state.textRange = NSRange(location: state.text.utf16.count, length: 0)
                }
                if let uploadBox = state.uploadBox {
                    return .merge(
                        .send(.binding(.set(\.bbPanel.existsFiles, uploadBox.existsAttachments.map {
                            .init(
                                name: $0.name,
                                type: $0.type == .image ? .image : .file,
                                serverId: $0.id
                            )
                        }))),
                        .send(.binding(.set(\.bbPanel.allowedExtensions, uploadBox.allowedExtensions)))
                    )
                }
                
            case let .bbPanel(.delegate(.tagTapped(tag))):
                if let nsRange = state.textRange,
                   let range = Range(nsRange, in: state.text),
                   !state.text.isEmpty {
                    // If we're inserting bb code without selected range
                    if range.isEmpty {
                        let location = nsRange.location + tag.0.utf16.count
                        state.text.insert(contentsOf: "\(tag.0)\(tag.1)", at: range.lowerBound)
                        state.textRange = NSRange(location: location, length: 0)
                    } else {
                        state.text.insert(contentsOf: tag.1, at: range.upperBound)
                        state.text.insert(contentsOf: tag.0, at: range.lowerBound)
                        state.textRange = NSRange(
                            location: nsRange.location + tag.0.utf16.count,
                            length: nsRange.length
                        )
                    }
                } else {
                    state.text = "\(tag.0)\(tag.1)"
                    state.textRange = NSRange(location: tag.0.utf16.count, length: 0)
                }
                state.focus = state.id
                
            case .binding, .bbPanel:
                break
            }
            return .none
        }
    }
}

// MARK: - View

@ViewAction(for: FormEditorFeature.self)
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
                        content: $store.text,
                        placeholder: LocalizedStringResource(stringLiteral: store.placeholder),
                        focusEqual: store.id,
                        focus: $focusedField,
                        minHeight: 144,
                        selection: $store.textRange,
                        bbPanel: {
                            BBPanelView(store: store.scope(\.bbPanel, action: \.bbPanel))
                                .onTapGesture {
                                    focusedField = store.id
                                }
                        }
                    )
                }
            }
            .bind($focusedField, to: $store.focus)
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

    FormEditorRow(
        store: Store(
            initialState: FormEditorFeature.State(
                id: 0,
                title: "Editor Title",
                description: "Editor Description",
                placeholder: "Editor Placeholder",
                flag: .required,
                defaultText: "Editor Default Text"
            )
        ) {
            FormEditorFeature()
        },
        focusedField: $focusedField
    )
}
