//
//  BBPanelView.swift
//  ForPDA
//
//  Created by Xialtal on 28.12.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI

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
            VStack {
                if store.showUploadBox {
                    UploadBox()
                }
                
                if #available(iOS 26.0, *) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            switch store.viewState {
                            case .tags:
                                Tags()
                            case .colorPicker:
                                Text("ColorPicker")
                            case .fontSizePicker:
                                FontSize()
                            }
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 12)
                    }
                    .sheet(isPresented: Binding($store.destination.sizeTag)) {
                        Picker("Select text size", selection: $store.textSize) {
                            ForEach(1..<8) { size in
                                Text(verbatim: "\(size)")
                            }
                        }
                        .pickerStyle(.wheel)
                        .presentationDetents([.medium])
                    }
                    .sheet(item: $store.scope(state: \.destination?.listTag, action: \.destination.listTag)) { store in
                        NavigationStack {
                            ListTagBuilderView(store: store)
                        }
                    }
                    .sheet(isPresented: Binding($store.destination.colorTag)) {
                        ColorPickerView(onColorSelected: { color in
                            if let color = color.hexColor {
                                send(.colorSelected(color))
                            }
                        })
                        .presentationDetents([.medium])
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
                    .animation(.bouncy, value: store.viewState)
                    .background(.bar.opacity(0.5), in: .capsule)
                    .glassEffect()
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    .onAppear {
                        send(.onAppear)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            Button {
                                
                            } label: {
                                Image(systemSymbol: .plusAppFill)
                                    .foregroundStyle(Color(.Labels.primary))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 6)
                        .padding(.bottom, 8)
                        .padding(.horizontal, 12)
                        .border(Color(.red/*Background.secondary*/))
                        .background(Color(.Background.secondary))
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func FontSize() -> some View {
        Button {
            send(.returnTagsButtonTapped)
        } label: {
            Image(systemName: "xmark")
                .font(.title3)
                .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        
        ForEach(2..<9) { size in
            Button {
                // TODO: dsaddd
            } label: {
                Image(systemName: "\(size).square")
                    .font(.title3)
                    .foregroundStyle(tintColor)
            }
            .buttonStyle(.plain)
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
    
    private func tagButtonColor(_ tag: BBPanelTag) -> Color {
        return tag == .upload && (store.isUploading || store.showUploadBox)
            ? tintColor
            : Color(.Labels.primary)
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
            
            UploadBoxView(store: store.scope(state: \.upload, action: \.upload))
                .padding(.bottom, 32)
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .background {
            if #available(iOS 26.0, *) {
                UnevenRoundedRectangle(cornerRadii: .init(
                    topLeading: 28,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 28
                ))
                .fill(Color(.Background.primary))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.primary))
            }
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

// MARK: - Helpers

extension Color {
    var hexColor: String? {
        let components = self.cgColor?.components
        guard let r = components?[0], let g = components?[1], let b = components?[2] else {
            return nil
        }
        return String(format: "#%02x%02x%02x", Int(r * 255), Int(g * 255), Int(b * 255))
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
