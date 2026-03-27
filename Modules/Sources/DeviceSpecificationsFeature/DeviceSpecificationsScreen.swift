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

@ViewAction(for: DeviceSpecificationsFeature.self)
public struct DeviceSpecificationsScreen: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<DeviceSpecificationsFeature>
    
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
            .navigationTitle(Text("DevDB", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.Background.primary))
            .overlay {
                if store.isLoading {
                    PDALoader()
                        .frame(width: 24, height: 24)
                }
            }
            .onAppear {
                send(.onAppear)
            }
        }
    }
    
    // MARK: - Header
    
    @ViewBuilder
    private func Header(_ specs: DeviceSpecificationsResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: "\(specs.vendorName) \(specs.deviceName)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color(.Labels.primary))
            
            HeaderImages(specs.images)
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
    private func HeaderImages(_ images: [DeviceSpecificationsResponse.DeviceImage]) -> some View {
        HStack(spacing: 8) {
            ForEach(images, id: \.url.hashValue) { image in
                LazyImage(url: image.url) { state in
                    Group {
                        if let image = state.image {
                            image.resizable().scaledToFill()
                        } else {
                            Color(.systemBackground)
                        }
                    }
                    .skeleton(with: state.isLoading, shape: .rectangle)
                }
                .frame(width: 37, height: 75)
                .clipped()
            }
        }
    }
    
    private func SpecificationSection(_ spec: DeviceSpecificationsResponse.Specification) -> some View {
        Section {
            ForEach(spec.entries, id: \.name) { entry in
                Row(title: entry.name, type: .description(entry.value))
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
    
    enum RowType {
        case description(String)
        case bigDescription(String)
    }
    
    @ViewBuilder
    private func Row(title: String, type: RowType, action: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 0) { // Hacky HStack to enable tap animations
            Button {
                action()
            } label: {
                HStack(spacing: 0) {
                    Text(verbatim: title)
                        .font(.body)
                        .foregroundStyle(Color(.Labels.primary))
                    
                    Spacer(minLength: 8)
                    
                    switch type {
                    case let .description(text):
                        Text(verbatim: text)
                            .font(.body)
                            .foregroundStyle(Color(.Labels.teritary))
                        
                    case let .bigDescription(text):
                        Text(verbatim: text)
                            .font(.body)
                            .foregroundStyle(Color(.Labels.teritary))
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .buttonStyle(.plain)
        .frame(height: 60)
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
