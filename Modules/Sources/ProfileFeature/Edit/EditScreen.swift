//
//  EditScreen.swift
//  ForPDA
//
//  Created by Xialtal on 28.08.25.
//

import SwiftUI
import ComposableArchitecture
import NukeUI
import Models
import SharedUI
import PhotosUI

@ViewAction(for: EditFeature.self)
public struct EditScreen: View {
    
    @Perception.Bindable public var store: StoreOf<EditFeature>
    @Environment(\.tintColor) private var tintColor
    
    @State private var pickerItem: PhotosPickerItem?
    
    @FocusState var isStatusFocused: Bool
    
    public init(store: StoreOf<EditFeature>) {
        self.store = store
    }
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                List {
                    AvatarRow()
                    
                    if store.isUserCanEditStatus {
                        Field(
                            content: Binding(unwrapping: $store.draftUser.status, default: ""),
                            title: LocalizedStringKey("Status")
                        )
                    } else {
                        // TODO: Some notify about it?
                    }
                    
                    Field(
                        content: Binding(unwrapping: $store.draftUser.signature, default: ""),
                        title: LocalizedStringKey("Signature")
                    )
                    
                    Field(
                        content: Binding(unwrapping: $store.draftUser.aboutMe, default: ""),
                        title: LocalizedStringKey("About me")
                    )
                    
                    Section {
                        UserBirthday()
                        UserGender()
                    }
                    .listRowBackground(Color(.Background.teritary))
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    
                    Field(
                        content: Binding(unwrapping: $store.draftUser.city, default: ""),
                        title: LocalizedStringKey("City")
                    )
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Text("Edit profile", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            ._safeAreaBar(edge: .bottom) {
                SendButton()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        send(.cancelButtonTapped)
                    } label: {
                        Text("Cancel", bundle: .module)
                            .foregroundStyle(tintColor)
                    }
                    .disabled(store.isSending)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Send Button
    
    @ViewBuilder
    private func SendButton() -> some View {
        Button {
            send(.saveButtonTapped)
        } label: {
            if store.isSending {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            } else {
                Text("Send", bundle: .module)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            }
        }
        .disabled(store.isSending)
        .disabled(store.isSavingDisabled)
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .frame(height: 48)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background {
            if #available(iOS 26, *) {
                // No background
            } else {
                Color(.Background.primary)
            }
        }
    }
    
    // MARK: - User Birthday Picker
    
    @ViewBuilder
    private func UserBirthday() -> some View {
        if let date = store.birthdayDate {
            DatePicker(
                selection: Binding(unwrapping: $store.birthdayDate, default: date),
                displayedComponents: .date
            ) {
                Text("Birthday date", bundle: .module)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.primary))
            }
            .padding(12)
            .frame(height: 60)
            .cornerRadius(10)
            .swipeActions(edge: .trailing) {
                Button {
                    send(.wipeBirthdayDate)
                } label: {
                    Image(systemSymbol: .trash)
                }
                .tint(.red)
            }
        } else {
            HStack {
                Text("Birthday date", bundle: .module)
                    .font(.body)
                    .foregroundStyle(Color(.Labels.primary))
                
                Spacer()
                
                Button {
                    send(.setBirthdayDate)
                } label: {
                    Text("Set", bundle: .module)
                        .textCase(.uppercase)
                }
                .cornerRadius(12)
                .foregroundStyle(tintColor)
            }
            .padding(12)
            .frame(height: 60)
            .cornerRadius(10)
        }
    }
    
    // MARK: - User Gender Picker
    
    @ViewBuilder
    private func UserGender() -> some View {
        Picker(
            LocalizedStringResource("Gender", bundle: .module),
            selection: Binding(unwrapping: $store.draftUser.gender, default: .unknown)
        ) {
            ForEach(User.Gender.allCases) { gender in
                Text(gender.title, bundle: .module)
                    .tag(gender)
            }
        }
        .padding(12)
        .frame(height: 60)
        .cornerRadius(10)
    }
    
    // MARK: - Avatar
    
    @ViewBuilder
    private func AvatarRow() -> some View {
        VStack {
            Circle()
                .stroke(
                    store.isUserSetAvatar ? Color.clear : tintColor,
                    style: StrokeStyle(lineWidth: 1, dash: [8])
                )
                .overlay(alignment: .bottomTrailing) {
                    AvatarContextMenu()
                }
                .background {
                    if store.isAvatarUploading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .foregroundStyle(Color(.Labels.quintuple))
                    } else {
                        if store.isUserSetAvatar {
                            LazyImage(url: store.draftUser.imageUrl) { state in
                                Group {
                                    if let image = state.image {
                                        image.resizable().scaledToFill()
                                    } else {
                                        Image(systemSymbol: .personCropCircle)
                                            .font(.title)
                                            .foregroundStyle(Color(.Labels.quintuple))
                                    }
                                }
                                .skeleton(with: state.isLoading, shape: .circle)
                            }
                            .clipShape(Circle())
                        } else {
                            Image(systemSymbol: .personCropCircle)
                                .font(.title)
                                .foregroundStyle(Color(.Labels.quintuple))
                        }
                    }
                }
                .frame(width: 100, height: 100)
                .background(Circle().foregroundColor(Color(.Background.teritary)))
                .padding(.bottom, 8)
            
            Text("File size should not be more that 32 kb and max 100x100 pixels", bundle: .module)
                .font(.caption)
                .foregroundStyle(Color(.Labels.teritary))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .photosPicker(
            isPresented: Binding($store.destination.avatarPicker),
            selection: $pickerItem,
            matching: .any(of: [.images, .screenshots])
        )
        .task(id: pickerItem) {
            guard let data = try? await pickerItem?.loadTransferable(type: Data.self) else {
                return
            }
            guard let image = UIImage(data: data) else {
                return
            }
            
            if data.count <= 32768 /* should be max 32kb size */ {
                if image.size.width <= 100, image.size.height <= 100 {
                    send(.avatarSelected(data))
                } else {
                    send(.onAvatarBadWidthHeightProvided)
                }
            } else {
                send(.onAvatarBadFileSizeProvided)
            }

            // Drop last selected avatar.
            // Need, because photosPicker remember last choice.
            pickerItem = nil
        }
    }
    
    // MARK: - Avatar Context Menu
    
    @ViewBuilder
    private func AvatarContextMenu() -> some View {
        Menu {
            Button {
                send(.addAvatarButtonTapped)
            } label: {
                HStack {
                    Text("Add avatar", bundle: .module)
                    Image(systemSymbol: .plusCircle)
                }
            }

            if store.isUserSetAvatar {
                Button(role: .destructive) {
                    send(.deleteAvatar)
                } label: {
                    HStack {
                        Text("Delete avatar", bundle: .module)
                        Image(systemSymbol: .trash)
                    }
                }
                .tint(.red)
            }
        } label: {
            Image(systemSymbol: .ellipsis)
                .font(.body)
                .foregroundStyle(Color(.Labels.primaryInvariably))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(tintColor)
                        .clipShape(Circle())
                )
        }
        .onTapGesture {} // DO NOT DELETE, FIX FOR IOS 17
    }
    
    // MARK: - Helpers
    
    @ViewBuilder
    private func Field(
        content: Binding<String>,
        title: LocalizedStringKey
    ) -> some View {
        Section {
            SharedUI.Field(
                text: content,
                description: "",
                guideText: "",
                isFocused: $isStatusFocused
            )
        } header: {
            Header(title: title)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    private func Header(title: LocalizedStringKey) -> some View {
        Text(title, bundle: .module)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("") {
    NavigationStack {
        EditScreen(
            store: Store(
                initialState: EditFeature.State(user: .mock)
            ) {
                EditFeature()
            } withDependencies: {
                $0.apiClient.updateUserAvatar = { @Sendable _, _ in
                    try await Task.sleep(for: .seconds(3))
                    return .success(URL(string: "https://github.com/SubvertDev/ForPDA/raw/main/Images/logo.png")!)
                }
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
