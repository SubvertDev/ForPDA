//
//  CreateChatScreen.swift
//  QMSListFeature
//
//  Created by Ilia Lubianoi on 16.05.2026.
//

import ComposableArchitecture
import SharedUI
import SwiftUI

@ViewAction(for: CreateChatFeature.self)
public struct CreateChatScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<CreateChatFeature>
    
    @Environment(\.tintColor) private var tintColor
    
    @FocusState public var focus: CreateChatFeature.Field?
    
    // MARK: - Init
    
    public init(store: StoreOf<CreateChatFeature>) {
        self.store = store
    }
        
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        Section {
                            VStack(spacing: 0) {
                                Field(
                                    content: $store.username.removeDuplicates(),
                                    placeholder: LocalizedStringResource("Enter...", bundle: .module),
                                    focusEqual: .username,
                                    focus: $focus,
                                    characterLimit: 26
                                )
                                .overlay(alignment: .trailing) {
                                    if store.isSearchingUsers {
                                        ProgressView()
                                            .frame(width: 22, height: 22)
                                            .padding(.horizontal, 12)
                                    } else if store.selectedSearchUser != nil {
                                        EmptyView() // ShowProfileButton()
                                    }
                                }
                                
                                if store.shouldShowSearchUsers {
                                    VStack(spacing: 0) {
                                        ForEach(store.searchUsers) { user in
                                            Button {
                                                send(.searchUserSelected(user))
                                            } label: {
                                                Text(user.name)
                                                    .font(.body)
                                                    .lineLimit(1)
                                                    .foregroundStyle(Color(.Labels.primary))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    .background(Color(.Background.teritary))
                                                    .contentShape(Rectangle())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .clipShape(.rect(cornerRadius: 16))
                                    .padding(.top, 8)
                                }
                            }
                            .padding(.bottom, 28)
                        } header: {
                            Header("Username")
                        }
                        
                        Section {
                            Field(
                                content: $store.chatTitle.removeDuplicates(),
                                placeholder: LocalizedStringResource("Enter...", bundle: .module),
                                focusEqual: .chatTitle,
                                focus: $focus
                            )
                            .padding(.bottom, 28)
                        } header: {
                            Header("Chat title")
                        }
                        
                        Section {
                            Field(
                                content: $store.message.removeDuplicates(),
                                placeholder: LocalizedStringResource("Enter...", bundle: .module),
                                focusEqual: .message,
                                focus: $focus
                            )
                            .padding(.bottom, 28)
                        } header: {
                            Header("Message")
                        }
                    }
                    .padding(.horizontal, 16)
                }
                ._safeAreaBar(edge: .bottom) {
                    Button {
                        send(.sendButtonTapped)
                    } label: {
                        Text("Send", bundle: .module)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(tintColor)
                    .padding(.horizontal, 16)
                    .disabled(!store.canSend)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        if #available(iOS 26, *) {
                            Button(role: .close) {
                                send(.closeButtonTapped)
                            }
                        } else {
                            Button {
                                send(.closeButtonTapped)
                            } label: {
                                Text("Close", bundle: .module)
                                    .foregroundStyle(tintColor)
                            }
                        }
                    }
                }
            }
            .navigationTitle(Text("Create chat", bundle: .module))
            ._toolbarTitleDisplayMode(.inline)
            .animation(.default, value: store.isSearchingUsers)
            .animation(.default, value: store.shouldShowSearchUsers)
            .bind($store.focus, to: $focus)
            .onTapGesture {
                send(.viewTapped)
            }
        }
    }
    
    private func Header(_ text: LocalizedStringKey) -> some View {
        Text(text, bundle: .module)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
    }
    
    // MARK: - Show Profile Button
    
    private func ShowProfileButton() -> some View {
        Button {
            
        } label: {
            HStack(spacing: 0) {
                Text("Profile", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(Color(.Labels.teritary))
                
                Image(systemSymbol: .arrowUpRight)
                    .frame(width: 32, height: 32)
                    .foregroundStyle(tintColor)
            }
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Previews

@available(iOS 17, *)
#Preview {
    @Previewable @State var store = Store(
        initialState: CreateChatFeature.State()
    ) {
        CreateChatFeature()
    }
    
    return NavigationStack {
        CreateChatScreen(store: store)
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
