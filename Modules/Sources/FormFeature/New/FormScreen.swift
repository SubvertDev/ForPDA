//
//  FormScreen.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 08.08.2025.
//

import ComposableArchitecture
import Models
import SharedUI
import SwiftUI

// MARK: - Form Screen

@ViewAction(for: FormFeature.self)
public struct FormScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<FormFeature>
    @FocusState private var focusedField: Int?
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<FormFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ScrollView(.vertical) {
                VStack(spacing: 28) {
                    ForEach(store.scope(state: \.rows, action: \.rows)) { fieldStore in
                        FormFieldRow(store: fieldStore, focusedField: $focusedField)
                    }
                    
                    if store.rows.count == 1 && store.inPostEditingMode {
                        EditReasonView(
                            id: 1,
                            text: $store.editReasonText,
                            isEditingReasonEnabled: $store.isEditingReasonEnabled,
                            isShowMarkEnabled: $store.isShowMarkEnabled,
                            focusedField: $focusedField,
                            canShowShowMark: store.canShowShowMark
                        )
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(Text(navigationTitleText(), bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                PublishButton()
            }
            .onTapGesture {
                focusedField = nil
            }
            .overlay {
                if store.rows.isEmpty || store.isFormLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .toolbar {
                Toolbar()
            }
            .background(Color(.Background.primary))
            .disabled(store.isPublishing)
            .animation(.default, value: store.isPublishing)
            .bind($store.focusedField, to: $focusedField)
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Publish Button
    
    @ViewBuilder
    private func PublishButton() -> some View {
        Button {
            send(.publishButtonTapped)
        } label: {
            if store.isPublishing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            } else {
                Text("Publish", bundle: .module)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .disabled(store.isPublishButtonDisabled)
        .frame(height: 48)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.Background.primary))
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private func Toolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                send(.cancelButtonTapped)
            } label: {
                Text("Cancel", bundle: .module)
            }
            .tint(tintColor)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                send(.previewButtonTapped)
            } label: {
                Image(systemSymbol: .eye)
                    .font(.body)
                    .frame(width: 34, height: 22)
            }
            .tint(tintColor)
            .disabled(store.isPreviewButtonDisabled)
        }
    }
    
    // MARK: - Helpers
    
    private func navigationTitleText() -> LocalizedStringKey {
        return switch store.type {
        case let .post(type, _, _):
            switch type {
            case .new:  "New post"
            case .edit: "Edit post"
            }
        case .topic:  "New topic"
        case .report: "Send report"
        }
    }
}

// MARK: - Previews

#Preview("Form (Simple, New)") {
    NavigationStack {
        FormScreen(
            store: Store(
                initialState: FormFeature.State(
                    type: .post(type: .new, topicId: 0, content: .simple("", []))
                )
            ) {
                FormFeature()
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Form (Simple, Edit)") {
    let id = 0
    @Shared(.userSession) var userSession = UserSession.mock(userId: 0)
    NavigationStack {
        FormScreen(
            store: Store(
                initialState: FormFeature.State(
                    type: .post(type: .edit(postId: 0), topicId: 0, content: .simple("", []))
                )
            ) {
                FormFeature()
            } withDependencies: {
                $0.cacheClient.getUser = { _ in
                    return User.mock(id: id, group: .admin)
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Form (Template)") {
    NavigationStack {
        FormScreen(
            store: Store(
                initialState: FormFeature.State(
                    type: .post(type: .new, topicId: 0, content: .template(""))
                )
            ) {
                FormFeature()
            } withDependencies: {
                $0.apiClient.getTemplate = { _, _ in
                    return [
                        .mockTitle,
                        .mockText,
                        .mockEditor,
                        .mockUploadBox,
                    ]
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Form (Report, Post)") {
    NavigationStack {
        FormScreen(
            store: Store(
                initialState: FormFeature.State(
                    type: .report(id: 0, type: .post)
                )
            ) {
                FormFeature()
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
