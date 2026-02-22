//
//  UploadBoxView.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.26.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI

@ViewAction(for: UploadBoxFeature.self)
public struct UploadBoxView: View {
    
    // MARK: - Properties
    
    @Perception.Bindable public var store: StoreOf<UploadBoxFeature>
    @Environment(\.tintColor) private var tintColor
    
    @State private var pickerItems: [PhotosPickerItem] = []
    
    // MARK: - Init
    
    public init(store: StoreOf<UploadBoxFeature>) {
        self.store = store
    }
    
    // MARK: - Body
    
    public var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                WithPerceptionTracking {
                    switch store.type {
                    case .bbPanel:
                        FilesGrid()
                    case .form:
                        if store.files.isEmpty {
                            FormUploadView()
                        } else {
                            FilesGrid()
                        }
                    }
                }
            }
            .confirmationDialog(
                $store.scope(
                    state: \.destination?.confirmationDialog,
                    action: \.destination.confirmationDialog
                )
            )
            .fileImporter(
                isPresented: Binding($store.destination.fileImporter),
                allowedContentTypes: [.item], // server will decide
                allowsMultipleSelection: true,
                onCompletion: { result in
                    switch result {
                    case let .success(urls):
                        send(.fileImporterURLsRecieved(urls))
                    case let .failure(error):
                        print("File importer error: \(error)")
#warning("Handle error")
                    }
                }
            )
            .photosPicker(
                isPresented: Binding($store.destination.photosPicker),
                selection: $pickerItems,
                maxSelectionCount: 10
            )
            .task(id: pickerItems) {
                var photos: [UploadBoxFeature.FileType] = []
                for item in pickerItems {
                    if let url = try? await item.loadTransferable(type: URL.self) {
                        let type = item.supportedContentTypes.first
                        photos.append(.image(url: url, ext: type?.preferredFilenameExtension))
                    }
                }
                send(.photosPickerPhotosSelected(photos))
            }
            .tint(tintColor)
        }
    }
    
    // MARK: - Form Upload View
    
    @ViewBuilder
    private func FormUploadView() -> some View {
        Button {
            send(.selectFilesButtonTapped)
        } label: {
            VStack(spacing: 8) {
                Image(systemSymbol: .docBadgePlus)
                    .font(.title)
                    .frame(width: 48, height: 48)
                
                Text("Select files...", bundle: .module)
                    .font(.body)
                    .foregroundColor(Color(.Labels.quaternary))
            }
            .frame(maxWidth: .infinity, minHeight: 144)
            .background {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.Background.teritary))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8]))
            }
        }
        .disabled(store.isAnyFileUploading)
    }
    
    // MARK: - Files Grid
    
    private func FilesGrid() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button {
                    send(.selectFilesButtonTapped)
                } label: {
                    Image(systemSymbol: .plus)
                        .font(.title)
                        .foregroundStyle(tintColor)
                        .frame(width: 48, height: 48)
                }
                .frame(minWidth: 48, maxWidth: 48, minHeight: 144)
                .padding(.horizontal, 12)
                .background(Color(.Background.teritary))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .disabled(store.isAnyFileUploading)
                
                ForEach(store.files, id: \.id) { file in
                    FileView(file)
                }
                
                if store.files.isEmpty {
                    HStack {
                        Image(systemSymbol: .infoCircle)
                            .font(.body)
                            .foregroundStyle(Color(.Labels.teritary))
                        
                        Text("The selected file will be inserted into the text as code wherever your cursor is located. Or it will also be automatically added to the end of the post.", bundle: .module)
                            .font(.footnote)
                            .foregroundStyle(Color(.Labels.teritary))
                    }
                    .padding(.leading, 6)
                    .padding(.vertical, 12)
                    .frame(width: 296)
                }
            }
        }
        .animation(.default, value: store.files)
    }
    
    // MARK: - File View
    
    @ViewBuilder
    private func FileView(_ file: UploadBoxFile) -> some View {
        VStack(spacing: 0) {
            if file.isUploading {
                ProgressView()
                    .frame(width: 28, height: 28)
            } else if file.isUploadError {
                Text(verbatim: "File upload ERROR")
                    .font(.title)
                    .foregroundColor(tintColor)
            } else {
                Image(systemSymbol: file.type == .file ? .doc : .photo)
                    .font(.title)
                    .foregroundColor(tintColor)
                    .frame(width: 48, height: 48)
                
                Text(file.name)
                    .font(.footnote)
                    .foregroundStyle(Color(.Labels.primary))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 12)
        .frame(minWidth: 144, maxWidth: 144, minHeight: 144)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.Background.teritary))
        )
        .overlay(alignment: .topTrailing) {
            Button {
                send(.removeFileButtonTapped(file))
            } label: {
                Circle()
                    .fill(Color(.Background.teritary))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Image(systemSymbol: .xmark)
                            .font(.body)
                            .foregroundStyle(Color(.Labels.teritary))
                    }
                    .padding([.top, .trailing], 6)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Previews

#Preview("Form Upload Box (Empty)") {
    UploadBoxView(
        store: Store(
            initialState: UploadBoxFeature.State(
                type: .form,
                allowedExtensions: ["jpg", "jpeg", "gif", "png"]
            )
        ) {
            UploadBoxFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Form Upload Box (Filled, 3)") {
    UploadBoxView(
        store: Store(
            initialState: UploadBoxFeature.State(
                type: .form,
                allowedExtensions: ["jpg", "jpeg", "gif", "png"],
                files: [
                    .init(name: "File 1", type: .file, data: Data()),
                    .init(name: "Image 1", type: .image, data: Data()),
                    .init(name: "File 2", type: .file, data: Data()),
                ]
            )
        ) {
            UploadBoxFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("BBPanel Upload Box (Empty)") {
    UploadBoxView(
        store: Store(
            initialState: UploadBoxFeature.State(
                type: .bbPanel,
                allowedExtensions: ["jpg", "jpeg", "gif", "png"]
            )
        ) {
            UploadBoxFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("BBPanel Upload Box (Filled, 3)") {
    UploadBoxView(
        store: Store(
            initialState: UploadBoxFeature.State(
                type: .bbPanel,
                allowedExtensions: ["jpg", "jpeg", "gif", "png"],
                files: [
                    .init(name: "File 1", type: .file, data: Data()),
                    .init(name: "Image 1", type: .image, data: Data()),
                    .init(name: "File 2", type: .file, data: Data()),
                ]
            )
        ) {
            UploadBoxFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}
