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
                .onAppear {
                    store.send(.onAppear)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.dismissButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.previewButtonTapped)
                    } label: {
                        Image(systemSymbol: .eye)
                            .font(.body)
                            .frame(width: 34, height: 22)
                    }
                    .disabled(store.textContent.isEmptyTrimmed())
                }
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
            Text("Publish", bundle: .module)
                .frame(maxWidth: .infinity)
                .padding(8)
        }
        .buttonStyle(.borderedProminent)
        .frame(height: 48)
        .disabled(store.textContent.isEmptyTrimmed())
        
        Spacer()
    }
}

// MARK: - Helpers

private extension WriteFormScreen {
    
    private func formTitle() -> LocalizedStringKey {
        return switch store.formFor {
        case .post: LocalizedStringKey("New post")
        case .topic: LocalizedStringKey("New topic")
        case .report: LocalizedStringKey("Send report")
        }
    }
}

private extension String {
    
    func isEmptyTrimmed() -> Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        WriteFormScreen(
            store: Store(
                initialState: WriteFormFeature.State(
                    formFor: .topic(forumId: 0, content: [])
                )
            ) {
                WriteFormFeature()
            }
        )
        .tint(Color(.Theme.primary))
    }
}
