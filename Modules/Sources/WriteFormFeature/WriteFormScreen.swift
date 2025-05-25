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

public struct WriteFormScreen: View {
    
    @Perception.Bindable var store: StoreOf<WriteFormFeature>
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
                .sheet(item: $store.scope(state: \.preview, action: \.preview)) { store in
                    NavigationStack {
                        FormPreviewView(store: store)
                    }
                }
                .overlay {
                    if store.formFields.isEmpty || store.isFormLoading {
                        PDALoader()
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .disabled(store.isPublishing)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.dismissButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                    .disabled(store.isPublishing)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.previewButtonTapped)
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
                store.send(.onAppear)
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
                                    store.send(.updateFieldContent(index, content!))
                                }
                                return store.textContent
                            }
                        )
                    }
                    .padding(.top, 16)
                }
            }
        }
        
        Spacer()
        
        Button {
            store.send(.publishButtonTapped)
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
}

// MARK: - Helpers

private extension WriteFormScreen {
    
    private func formTitle() -> LocalizedStringKey {
        return switch store.formFor {
        case .post: LocalizedStringKey("New post")
        case .edit: LocalizedStringKey("Edit post")
        case .topic: LocalizedStringKey("New topic")
        case .report: LocalizedStringKey("Send report")
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
                    formFor: .post(topicId: 0, content: .simple("", []))
                )
            ) {
                WriteFormFeature()
            } withDependencies: {
                $0.apiClient.sendPost = { _ in
                    try await Task.sleep(for: .seconds(3))
                    return PostSend(id: 0, topicId: 0, offset: 0)
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
                    formFor: .edit(topicId: 0, postId: 0, content: .simple("Some text", []))
                )
            ) {
                WriteFormFeature()
            } withDependencies: {
                $0.apiClient.sendPost = { _ in
                    try await Task.sleep(for: .seconds(3))
                    return PostSend(id: 0, topicId: 0, offset: 0)
                }
            }
        )
    }
}
