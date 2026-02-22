//
//  ListTagBuilderView.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.26.
//

import SwiftUI
import ComposableArchitecture

@ViewAction(for: ListTagBuilderFeature.self)
public struct ListTagBuilderView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<ListTagBuilderFeature>
    @Environment(\.tintColor) private var tintColor
    
    @FocusState var focus: ListTagBuilderFeature.State.Field?
    
    // MARK: - Init
    
    public init(store: StoreOf<ListTagBuilderFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List {
                    Section {
                        ForEach(store.listItems) { item in
                            ItemField(id: item.id)
                        }
                        
                        AddItemButton()
                    } footer: {
                        Text("New list items are created automatically", bundle: .module)
                            .font(.footnote)
                            .foregroundStyle(Color(.Labels.teritary))
                    }
                    .listRowBackground(Color(.Background.teritary))
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("New list", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .bind($store.focus, to: $focus)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        send(.cancelButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                            .foregroundStyle(tintColor)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        send(.createButtonTapped)
                    } label: {
                        Text("Create", bundle: .module)
                            .foregroundStyle(tintColor)
                    }
                    .disabled(store.isAddItemButtonDisabled)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Add Item Button
    
    private func AddItemButton() -> some View {
        Button {
            send(.addListItemButtonTapped)
        } label: {
            Text("Add item", bundle: .module)
                .font(.body)
                .foregroundStyle(Color(.Labels.quaternary))
        }
        .buttonStyle(.plain)
        .disabled(store.isAddItemButtonDisabled)
    }
    
    // MARK: - Item Field
    
    @ViewBuilder
    public func ItemField(id: Int) -> some View {
        TextField(text: $store.listItems[id].content, axis: .vertical) {
            Text("Item \(id + 1)", bundle: .module)
                .font(.body)
                .foregroundStyle(Color(.Labels.quaternary))
        }
        .padding(.vertical, 11)
        .focused($focus, equals: .item(id))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(minHeight: 44)
        .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ListTagBuilderView(
            store: Store(
                initialState: ListTagBuilderFeature.State(
                    isBullet: true
                ),
            ) {
                ListTagBuilderFeature()
            }
        )
    }
}
