//
//  DeviceSpecificationsScreen.swift
//  ForPDA
//
//  Created by Xialtal on 23.12.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models
import NukeUI
import GalleryFeature

@ViewAction(for: DeviceSpecificationsFeature.self)
public struct DeviceSpecificationsScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<DeviceSpecificationsFeature>
    @Environment(\.tintColor) private var tintColor
    
    // MARK: - Init
    
    public init(store: StoreOf<DeviceSpecificationsFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            ZStack {
                Color(.Background.primary)
                    .ignoresSafeArea()
                
                if let specifications = store.specifications, !store.isLoading {
                    List {
                        Header(specifications)
                        
                        ForEach(specifications.specifications) { specification in
                            SpecificationSection(specification)
                        }
                    }
                    ._listSectionSpacing(28)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(Text(navigationTitleText()))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.Background.primary))
            .fullScreenCover(isPresented: Binding($store.destination.gallery)) {
                WithPerceptionTracking {
                    TabViewGallery(
                        gallery: store.specifications?.images.map{ $0.fullUrl } ?? [],
                        selectedImageID: store.selectedHeaderImageId
                    )
                }
            }
            .sheet(item: $store.destination.longEntry, id: \.self) { entry in
                NavigationStack {
                    DeviceSpecificationLongEntryView(title: entry.name, content: entry.value) {
                        send(.longEntryCloseButtonTapped)
                    }
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let specifications = store.specifications, store.isUserAuthorized {
                    MyDeviceButton(specifications.isMyDevice)
                }
            }
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .toolbar {
                ToolbarItem {
                    OptionsMenu()
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - My Device Button
    
    @ViewBuilder
    private func MyDeviceButton(_ myDevice: Bool) -> some View {
        Button {
            send(.markAsMyDeviceButtonTapped(myDevice))
        } label: {
            if store.isMyDeviceLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity)
                    .padding(8)
            } else {
                HStack {
                    Image(systemSymbol: myDevice ? .checkmarkCircleFill : .circle)
                    
                    Text(myDevice ? "My Device" : "Mark as My Device", bundle: .module)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
            }
        }
        ._buttonStyle(myDevice ? .borderedProminent : .bordered)
        .tint(tintColor)
        .disabled(store.isMyDeviceLoading || store.isDevicesLimit)
        .frame(height: 48)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.Background.primary))
        .animation(.default, value: store.isMyDeviceLoading)
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(_ specs: DeviceSpecifications) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: "\(specs.vendorName) \(specs.deviceName) \(specs.editionName)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(.Labels.primary))
            
            HeaderImages(specs.images)
            
            HeaderEditions(specs.editions)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 19)
        .background(
            Color(.Background.teritary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    @ViewBuilder
    private func HeaderImages(_ images: [DeviceSpecifications.DeviceImage]) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(images.enumerated()), id: \.element) { index, image in
                LazyImage(url: image.url) { state in
                    Group {
                        if let image = state.image {
                            image.resizable().scaledToFit()
                        } else {
                            Color(.systemBackground)
                        }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .frame(width: 75, height: 75)
                .clipped()
                .onTapGesture {
                    send(.headerImageTapped(index))
                }
            }
        }
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private func HeaderEditions(_ editions: [DeviceSpecifications.Edition]) -> some View {
        VStack(spacing: 6) {
            ForEach(editions, id: \.name) { edition in
                Button {
                    send(.editionButtonTapped(edition.subTag))
                } label: {
                    Text(verbatim: edition.name)
                        .foregroundStyle(Color(.Labels.teritary))
                }
            }
        }
    }
    
    // MARK: - Specification Section
    
    private func SpecificationSection(_ spec: DeviceSpecifications.Specification) -> some View {
        Section {
            ForEach(spec.entries, id: \.name) { entry in
                Row(entry: entry) {
                    send(.longEntryButtonTapped(entry))
                }
            }
        } header: {
            SectionHeader(title: spec.title)
        }
        .listRowBackground(Color(.Background.teritary))
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - Section Header
    
    @ViewBuilder
    private func SectionHeader(title: String) -> some View {
        Text(verbatim: title)
            .font(.subheadline)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .offset(x: 16)
            .padding(.bottom, 4)
    }
    
    // MARK: - Row
    
    @ViewBuilder
    private func Row(entry: DeviceSpecifications.Specification.Entry, action: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            ViewThatFits(in: .vertical) {
                HStack(spacing: 0) {
                    Text(verbatim: entry.name)
                        .font(.body)
                        .foregroundStyle(Color(.Labels.primary))
                    
                    Spacer(minLength: 8)
                    
                    Text(verbatim: entry.value)
                        .font(.body)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(Color(.Labels.teritary))
                }
                .contentShape(Rectangle())
                
                Button {
                    action()
                } label: {
                    HStack(spacing: 0) {
                        Text(verbatim: entry.name)
                            .font(.body)
                            .foregroundStyle(Color(.Labels.primary))
                        
                        Spacer(minLength: 8)
                        
                        HStack(spacing: 4) {
                            Text(verbatim: entry.value)
                                .font(.body)
                                .foregroundStyle(Color(.Labels.teritary))
                            
                            Image(systemSymbol: .chevronRight)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color(.Labels.quintuple))
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(height: 60)
    }
    
    // MARK: - Options Menu
    
    @ViewBuilder
    private func OptionsMenu() -> some View {
        Menu {
            ContextButton(text: LocalizedStringResource("Copy Link", bundle: .module), symbol: .docOnDoc) {
                send(.contextMenu(.copyLink))
            }
        } label: {
            Image(systemSymbol: .ellipsisCircle)
                .foregroundStyle(tintColor)
        }
    }
    
    // MARK: - Helpers
    
    private func navigationTitleText() -> String {
        return if let specifications = store.specifications {
            "\(specifications.deviceName) \(specifications.editionName)"
        } else {
            String(localized: "Loading...", bundle: .module)
        }
    }
}

// MARK: - Extensions

private extension Button {
    enum ButtonStyle {
        case bordered
        case borderedProminent
    }
    
    @ViewBuilder
    func _buttonStyle(_ style: ButtonStyle) -> some View {
        switch style {
        case .bordered:
            self.buttonStyle(BorderedButtonStyle())
        case .borderedProminent:
            self.buttonStyle(BorderedProminentButtonStyle())
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DeviceSpecificationsScreen(
            store: Store(
                initialState: DeviceSpecificationsFeature.State(
                    tag: "forpda",
                    subTag: nil
                ),
            ) {
                DeviceSpecificationsFeature()
            }
        )
    }
    .environment(\.tintColor, Color(.Theme.primary))
}
