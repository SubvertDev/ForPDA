//
//  UploadBoxView.swift
//  ForPDA
//
//  Created by Xialtal on 19.07.25.
//

import SwiftUI
import ComposableArchitecture
import SharedUI
import Models
import PhotosUI

public struct UploadBoxView: View {
    private let content: WriteFormFieldType.FormField
    private let allowedFileExtensions: [String]

    @State private var pickerItem: PhotosPickerItem?
    
    @State private var showFilePicker = false
    @State private var showImagePicker = false
    @State private var uploadOptionsShowing = false
    
    @State private var uploadboxFiles: [File] = []
    
    private let onUploadFile: (_ id: Int, _ event: FormUploadEvent) -> Void
    
    public init(
        _ content: WriteFormFieldType.FormField,
        _ extensions: [String],
        onUploadFile: @escaping (Int, FormUploadEvent) -> Void
    ) {
        self.content = content
        self.allowedFileExtensions = extensions
        self.onUploadFile = onUploadFile
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                Header(title: content.name, required: content.isRequired)
                
                if !uploadboxFiles.isEmpty {
                    Button {
                        uploadOptionsShowing = true
                    } label: {
                        Label("Add more", systemSymbol: .plus)
                            .font(.footnote)
                    }
                }
            }
            
            if !uploadboxFiles.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(uploadboxFiles) { file in
                            // TODO: Fix this...
                            file
                                //.frame(maxWidth: uploadboxFiles.count == 1 ? .infinity : 170)
                        }
                    }
                }
            } else {
                Button {
                    uploadOptionsShowing = true
                } label: {
                    VStack {
                        Image(systemSymbol: .docBadgePlus)
                            .font(.title)
                            .foregroundStyle(Color(.tintColor))
                            .frame(width: 48, height: 48)
                        
                        Text("Select files...", bundle: .module)
                            .font(.body)
                            .foregroundColor(Color(.Labels.quaternary))
                    }
                    .padding(.vertical, 15)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, minHeight: 144)
                    .background {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.Background.teritary))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(
                                Color(.tintColor),
                                style: StrokeStyle(lineWidth: 1, dash: [8])
                            )
                    }
                }
            }
            
            if !content.description.isEmpty {
                DescriptionText(text: content.description)
            }
        }
        .confirmationDialog("", isPresented: $uploadOptionsShowing, titleVisibility: .hidden) {
            Button("Select from Gallery") {
                showImagePicker = true
            }
            
            Button("Select from Files") {
                showFilePicker = true
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $pickerItem)
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                let fileId = url.hashValue + .random(in: 1..<100)
                uploadboxFiles.append(File(
                    id: fileId,
                    name: url.lastPathComponent,
                    type: .file,
                    isUploading: true,
                    onCancelButtonTapped: {
                        onUploadFile(fileId, .removed)
                        
                        //TODO: uploadboxFiles.remove(at: ...)
                        print("IMPLEMENT CANCELLATION!")
                    }
                ))
                onUploadFile(fileId, .uploading)
                
            case .failure(let error):
                onUploadFile(0, .selectError)
            }
        }
        .task(id: pickerItem) {
            guard let image = try? await pickerItem?.loadTransferable(type: Image.self) else {
                onUploadFile(0, .selectError)
                return
            }
            let fileId = Int.random(in: 1..<100)
            uploadboxFiles.append(File(
                id: fileId,
                name: "img-\(fileId)",
                type: .image(image),
                isUploading: false,
                onCancelButtonTapped: {
                    onUploadFile(fileId, .removed)
                    
                    //TODO: uploadboxFiles.remove(at: ...)
                    print("IMPLEMENT CANCELLATION!")
                }
            ))
            onUploadFile(fileId, .uploading)
            // Drop "remembered" image.
            pickerItem = nil
        }
    }
    
    // TODO: MAKE COMMON
    
    @ViewBuilder
    private func DescriptionText(text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(Color(.Labels.teritary))
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
    }

    // MARK: - Header
    
    @ViewBuilder
    private func Header(title: String, required: Bool) -> some View {
        HStack {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(Color(.Labels.teritary))
                .textCase(nil)
                .overlay(alignment: .bottomTrailing) {
                    if required {
                        Text(verbatim: "*")
                            .font(.headline)
                            .offset(x: 8)
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - File View

enum FileType: Equatable {
    case file
    case image(Image)
}

struct File: View, Identifiable {
    let id: Int
    let name: String
    let type: FileType
    let onCancelButtonTapped: () -> Void
    
    @State var isUploading: Bool
    
    init(
        id: Int,
        name: String,
        type: FileType,
        isUploading: Bool,
        onCancelButtonTapped: @escaping () -> Void
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isUploading = isUploading
        self.onCancelButtonTapped = onCancelButtonTapped
    }
    
    var body: some View {
        VStack {
            if !isUploading {
                if type == .file {
                    Image(systemSymbol: .doc)
                        .font(.title)
                        .foregroundStyle(Color(.tintColor))
                        .frame(width: 48, height: 48)
                    
                    Text(name)
                        .lineLimit(2)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(.Labels.primary))
                }
            } else {
                ProgressView()
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 12)
        .frame(minWidth: 170, maxWidth: .infinity, minHeight: 144)
        .background {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.Background.teritary))
                .overlay {
                    if !isUploading, case .image(let image) = type {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(minWidth: 170, maxWidth: .infinity, maxHeight: 144)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                onCancelButtonTapped()
            } label: {
                Image(systemSymbol: .xmark)
                    .font(.body)
                    .foregroundStyle(type == .file ? Color(.Labels.teritary) : Color(.Labels.primaryInvariably))
                    .frame(width: 30, height: 30)
                    .background(
                        Circle()
                            .fill(Color(.Background.quaternary))
                            .clipShape(Circle())
                    )
            }
            .padding(10)
        }
    }
}

// MARK: - File View Preview

#Preview("File View") {
    VStack {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                File(
                    id: 0,
                    name: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, se",
                    type: .file,
                    isUploading: false,
                    onCancelButtonTapped: {}
                )
                
                File(
                    id: 1,
                    name: "IMG",
                    type: .image(Image(.Settings.lightThemeExample)),
                    isUploading: false,
                    onCancelButtonTapped: {}
                )
            }
        }
        
        Color.white
    }
    .padding(.horizontal, 16)
}
