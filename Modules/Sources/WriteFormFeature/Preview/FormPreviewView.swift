//
//  FormPreviewView.swift
//  ForPDA
//
//  Created by Xialtal on 16.03.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models
import TopicBuilder

struct FormPreviewView: View {
    
    @Perception.Bindable var store: StoreOf<FormPreviewFeature>
    
    @Environment(\.tintColor) private var tintColor
    
    init(store: StoreOf<FormPreviewFeature>) {
        self.store = store
    }
    
    var body: some View {
        WithPerceptionTracking {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if !store.contentTypes.isEmpty {
                        ForEach(store.contentTypes, id: \.self) { type in
                            TopicView(type: type, attachments: []) { _ in
                                // Not handling URLs. Do not remove, cause else
                                // links will be opening in browser.
                            }
                        }
                    } else if !store.isPreviewLoading {
                        Text("Oops, error with loading preview :(", bundle: .module)
                            .font(.headline)
                            .foregroundStyle(tintColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(16)
                ._toolbarTitleDisplayMode(.inline)
                .navigationTitle(Text("Preview", bundle: .module))
            }
            .background(Color(.Background.primary))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        store.send(.cancelButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
            }
            .overlay {
                if store.isPreviewLoading && store.contentTypes.isEmpty {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}
