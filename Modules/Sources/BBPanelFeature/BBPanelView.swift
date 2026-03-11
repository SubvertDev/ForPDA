//
//  BBPanelView.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import UploadBoxFeature

@ViewAction(for: BBPanelFeature.self)
public struct BBPanelView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<BBPanelFeature>
    @Environment(\.tintColor) private var tintColor
    
    @State private var selectedColor: Color = .clear
    
    // MARK: - Init
    
    public init(store: StoreOf<BBPanelFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 32) {
                if store.showUploadBox {
                    UploadBox()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 24) {
                        switch store.viewState {
                        case .tags:
                            Tags()
                        case .fontSizes:
                            FontSizes()
                        }
                    }
                    .padding(.top, 6)
                    .padding(.bottom, 8)
                    .padding(.horizontal, 12)
                }
                .sheet(item: $store.scope(state: \.destination?.listTag, action: \.destination.listTag)) { store in
                    NavigationStack {
                        ListTagBuilderView(store: store)
                    }
                }
                .sheet(isPresented: Binding($store.destination.colorTag)) {
                    ColorsGrid()
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                }
                .alert(
                    BBPanelFeature.Localization.inputFullUrl,
                    isPresented: $store.destination.urlTag
                ) {
                    AlertInput({
                        send(.alertTagButtonTapped(.url))
                    })
                }
                .alert(
                    BBPanelFeature.Localization.inputSpoilerTitle,
                    isPresented: Binding($store.destination.spoilerWithTitleTag)
                ) {
                    AlertInput({
                        send(.alertTagButtonTapped(.spoilerWithTitle))
                    })
                }
                .background {
                    RoundedRectangle(cornerRadius: isLiquidGlass ? 28 : 14)
                        .fill(Color(.Background.primary))
                }
                .onAppear {
                    send(.onAppear)
                }
            }
        }
    }
    
    // MARK: - Tags
    
    @ViewBuilder
    private func Tags() -> some View {
        ForEach(store.tags, id: \.self) { tag in
            TagButton(tag)
        }
    }
    
    // MARK: - Tag Button
    
    @ViewBuilder
    private func TagButton(_ tag: BBPanelTag) -> some View {
        WithPerceptionTracking {
            Button {
                send(.tagButtonTapped(tag))
            } label: {
                Image(systemSymbol: tag.icon)
                    .font(.title3)
                    .foregroundStyle(tagButtonColor(tag))
                    .overlay(alignment: .topTrailing) {
                        if tag == .upload, store.uploadedFiles != 0 {
                            Circle()
                                .overlay {
                                    Text(verbatim: "\(store.uploadedFiles)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color(.Labels.primaryInvariably))
                                }
                                .frame(width: 21, height: 18)
                                .foregroundStyle(tintColor)
                                .offset(x: 10, y: -5)
                        }
                    }
            }
            .buttonStyle(.plain)
        }
    }
    
    private func tagButtonColor(_ tag: BBPanelTag) -> Color {
        return tag == .upload && (store.isUploading || store.showUploadBox)
            ? tintColor
            : Color(.Labels.primary)
    }
    
    // MARK: - Font Sizes
    
    @ViewBuilder
    private func FontSizes() -> some View {
        Button {
            send(.returnTagsButtonTapped)
        } label: {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundStyle(tintColor)
        }
        .buttonStyle(.plain)
        
        ForEach(1..<8) { size in
            Button {
                send(.fontSizeButtonTapped(size))
            } label: {
                Text(verbatim: "\(size)")
            }
            .font(.title2)
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Colors Grid
    
    @ViewBuilder
    private func ColorsGrid() -> some View {
        ZStack {
            Color(.Background.primary)
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                HStack {
                    Text("Select color", bundle: .module)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.Labels.primary))
                    
                    Spacer()
                    
                    Button {
                        send(.colorCancelButtonTapped)
                    } label: {
                        Image(systemSymbol: .xmark)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(.Labels.teritary))
                            .frame(width: 30, height: 30)
                            .background(
                                Circle()
                                    .fill(Color(.Background.quaternary))
                                    .clipShape(Circle())
                            )
                    }
                }
                .padding(.top, 18)
                
                Spacer()
                
                let colorsColumns = Array(repeating: GridItem(.flexible()), count: 5)
                LazyVGrid(columns: colorsColumns, spacing: 16) {
                    ForEach(BBPanelColor.allCases, id: \.self) { color in
                        Circle()
                            .fill(color.color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color(.Separator.secondary), lineWidth: color == .white ? 1 : 0)
                            )
                            .onTapGesture {
                                send(.colorButtonTapped(color.title))
                            }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Upload Box
    
    private func UploadBox() -> some View {
        VStack {
            HStack {
                Text("Attachments", bundle: .module)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.Labels.primary))
                
                Spacer()
                
                Button {
                    send(.hideUploadBoxButtonTapped)
                } label: {
                    Image(systemSymbol: .xmark)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(.Labels.teritary))
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(Color(.Background.quaternary))
                                .clipShape(Circle())
                        )
                }
            }
            
            WithPerceptionTracking {
                UploadBoxView(store: store.scope(state: \.upload, action: \.upload))
                    .padding(.bottom, 32)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: isLiquidGlass ? 28 : 14)
                .fill(Color(.Background.primary))
        }
        .frame(height: 190)
        .shadow(color: Color(.Labels.primary).opacity(0.15), radius: 10, y: 4)
    }
    
    // MARK: - Alert Input
    
    @ViewBuilder
    private func AlertInput(_ action: @escaping () -> Void) -> some View {
        TextField(String(), text: $store.alertInput)
        
        Button(LocalizedStringResource("Cancel", bundle: .module)) { }
        
        Button(LocalizedStringResource("OK", bundle: .module)) {
            action()
        }
        .disabled(store.alertInput.isEmpty)
    }
}

// MARK: - Previews

#Preview {
    BBPanelView(
        store: Store(
            initialState: BBPanelFeature.State(
                for: .post(isCurator: true, canModerate: true),
                supportsUpload: true
            ),
        ) {
            BBPanelFeature()
        }
    )
}
