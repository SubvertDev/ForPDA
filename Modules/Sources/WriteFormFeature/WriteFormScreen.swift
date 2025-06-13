//
//  WriteFormScreen.swift
//  ForPDA
//
//  Created by Xialtal on 14.03.25.
//

import Foundation
import ComposableArchitecture
import SwiftUI
import Models
import SharedUI

@ViewAction(for: WriteFormFeature.self)
public struct WriteFormScreen: View {
    
    @Perception.Bindable public var store: StoreOf<WriteFormFeature>
    @Environment(\.tintColor) private var tintColor
    
    @State private var isPreviewPresented: Bool = false
    
    public init(store: StoreOf<WriteFormFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            NavigationStack {
                VStack(alignment: .leading, spacing: 0) {
                    WriteForm()
                }
                .navigationTitle(Text(formTitle(), bundle: .module))
                .padding(.horizontal, 16)
                .background(Color(.Background.primary))
                .navigationBarTitleDisplayMode(.inline)
                .overlay {
                    if store.formFields.isEmpty || store.isFormLoading {
                        PDALoader()
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .disabled(store.isPublishing)
            .animation(.default, value: store.isPublishing)
            .animation(.default, value: store.isEditReasonToggleSelected)
            .animation(.default, value: store.isShowMarkToggleSelected)
            .alert($store.scope(state: \.destination?.alert, action: \.destination.alert))
            .sheet(item: $store.scope(state: \.destination?.preview, action: \.destination.preview)) { store in
                NavigationStack {
                    FormPreviewView(store: store)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        send(.dismissButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                    .disabled(store.isPublishing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        send(.previewButtonTapped)
                    } label: {
                        Image(systemSymbol: .eye)
                            .font(.body)
                            .frame(width: 34, height: 22)
                    }
                    .disabled(store.textContent.isEmptyAfterTrimming())
                    .disabled(store.isPublishing)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    @ViewBuilder
    private func WriteForm() -> some View {
        ScrollView {
            VStack {
                ForEach(store.formFields.indices, id: \.self) { index in
                    VStack {
                        WriteFormView(
                            type: store.formFields[index],
                            onUpdateContent: { content in
                                if content != nil {
                                    send(.updateFieldContent(index, content!))
                                }
                                return store.textContent
                            }
                        )
                    }
                    .padding(.top, 16)
                }
                
                if store.inPostEditingMode {
                    EditReason()
                }
            }
        }
        
        Spacer()
        
        Button {
            send(.publishButtonTapped)
        } label: {
            if store.isPublishing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .id(UUID())
                    .frame(maxWidth: .infinity)
                    .padding(8)
            } else {
                Text("Publish", bundle: .module)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
        }
        .buttonStyle(.borderedProminent)
        .frame(height: 48)
        .disabled(store.textContent.isEmptyAfterTrimming())
        .disabled(store.isPublishing)
        
        Spacer()
    }
    
    @ViewBuilder
    private func EditReason() -> some View {
        VStack {
            HStack(spacing: 0) {
                Text("Editing reason", bundle: .module)
                    .foregroundStyle(Color(.Labels.teritary))
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Toggle(String(""), isOn: $store.isEditReasonToggleSelected)
                    .labelsHidden()
            }
            .padding(.horizontal, 2)
            
            if store.isEditReasonToggleSelected {
                Field(text: $store.editReasonContent, description: "", guideText: "")
                    .disabled(store.isPublishing || !store.isEditReasonToggleSelected)
                
                if store.canShowShowMark {
                    Toggle(isOn: $store.isShowMarkToggleSelected) {
                        Text("Show mark", bundle: .module)
                            .font(.subheadline)
                            .foregroundStyle(Color(.Labels.secondary))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .toggleStyle(CheckBox())
                    .padding(6)
                }
            }
        }
        .padding(.top, 18)
    }
}

// MARK: - Helpers

private extension WriteFormScreen {
    
    private func formTitle() -> LocalizedStringKey {
        return switch store.formFor {
        case let .post(type, _, _):
            switch type {
            case .new:
                LocalizedStringKey("New post")
            case .edit:
                LocalizedStringKey("Edit post")
            }
        case .topic:
            LocalizedStringKey("New topic")
        case .report:
            LocalizedStringKey("Send report")
        }
    }
}

private extension String {
    
    func isEmptyAfterTrimming() -> Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Previews

#Preview("New Post") {
    NavigationStack {
        WriteFormScreen(
            store: Store(
                initialState: WriteFormFeature.State(
                    formFor: .post(type: .new, topicId: 0, content: .simple("", []))
                )
            ) {
                WriteFormFeature()
            } withDependencies: {
                $0.apiClient.sendPost = { _ in
                    try await Task.sleep(for: .seconds(3))
                    return .success(PostSend(id: 0, topicId: 0, offset: 0))
                }
            }
        )
        .tint(Color(.Theme.primary))
    }
}

#Preview("Edit Post") {
    NavigationStack {
        WriteFormScreen(
            store: Store(
                initialState: WriteFormFeature.State(
                    formFor: .post(
                        type: .edit(postId: 0),
                        topicId: 0,
                        content: .simple("Some text", [])
                    )
                )
            ) {
                WriteFormFeature()
            } withDependencies: {
                $0.apiClient.sendPost = { _ in
                    try await Task.sleep(for: .seconds(3))
                    return .success(PostSend(id: 0, topicId: 0, offset: 0))
                }
            }
        )
        .tint(Color(.Theme.primary))
    }
}

#Preview("Failure statuses") {
    Text("Failure statuses located in TopicScreen")
}
