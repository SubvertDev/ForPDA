//
//  FormUploadBoxFeature.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 19.07.2025.
//

#warning("to do")

import SwiftUI
import ComposableArchitecture
import PhotosUI

// MARK: - Feature

@Reducer
public struct FormUploadBoxFeature: Reducer {
    
    // MARK: - Helpers
    
    public struct File: Identifiable, Equatable {
        
        public enum FileType {
            case file, image
        }
        
        public let id: Int
        let name: String
        let type: FileType
        let data: Data
        
        public init(id: Int, name: String, type: FileType, data: Data) {
            self.id = id
            self.name = name
            self.type = type
            self.data = data
        }
    }
    
    var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // MARK: - Destination
    
    @Reducer(state: .equatable)
    public enum Destination {
        case confirmationDialog(ConfirmationDialogState<Dialog>)
        case fileImporter
        case photosPicker
        
        @CasePathable
        public enum Dialog {
            case gallery, files
        }
    }
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable, FormFieldConformable {
        @Presents public var destination: Destination.State?
        
        public let id: Int
        let title: String
        let description: String
        let flag: Int
        let allowedExtensions: [String]
        
        var isLoading: Bool
        public var files: [File]
        
        public init(
            id: Int,
            title: String,
            description: String,
            flag: Int,
            allowedExtensions: [String],
            isLoading: Bool = false,
            files: [File] = []
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.flag = flag
            self.allowedExtensions = allowedExtensions
            self.isLoading = isLoading
            self.files = files
        }
        
        func getValue() -> String {
            return files.map { "[\($0.id),\($0.name)]" }.joined(separator: ",")
        }
        
        func isValid() -> Bool {
            return !files.isEmpty
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)

        case view(View)
        public enum View {
            case selectFilesButtonTapped
            case removeFileButtonTapped(File)
            case addMoreButtonTapped
            case photosPickerPhotoSelected(Data)
            case fileImporterURLsRecieved([URL])
        }
        
        case `internal`(Internal)
        public enum Internal {
            case showFiles
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case filesHasBeenUploaded
        }
    }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> {
            state,
            action in
            switch action {
            case .binding:
                break
                
            case .delegate:
                break
                
            case .destination(.presented(.confirmationDialog(.files))):
                if isPreview {
                    return .send(.view(.fileImporterURLsRecieved([])))
                } else {
                    state.destination = .fileImporter
                }
                
            case .destination(.presented(.confirmationDialog(.gallery))):
                if isPreview {
                    return .send(.view(.photosPickerPhotoSelected(Data())))
                } else {
                    state.destination = .photosPicker
                }
                
            case .destination:
                break
                
            case .view(.selectFilesButtonTapped), .view(.addMoreButtonTapped):
                let dialogState = ConfirmationDialogState<Destination.Dialog>(
                    title: { TextState(verbatim: "") },
                    actions: {
                        ButtonState(action: .gallery) {
                            TextState("Choose from Gallery", bundle: .module)
                        }
                        ButtonState(action: .files) {
                            TextState("Choose from Files", bundle: .module)
                        }
                    }
                )
                state.destination = .confirmationDialog(dialogState)
                
            case let .view(.removeFileButtonTapped(file)):
                state.files.removeAll(where: { $0.id == file.id })
                
            case let .view(.photosPickerPhotoSelected(data)):
                let file = File(
                    id: state.files.count,
                    name: UUID().uuidString,
                    type: .image,
                    data: data
                )
                state.files.append(file)
                
            case let .view(.fileImporterURLsRecieved(urls)):
                var urls = urls
                if isPreview {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsURL.appending(path: "data.dat")
                    try! Data().write(to: fileURL)
                    urls.append(fileURL)
                }
                
                for url in urls {
                    guard let data = try? Data(contentsOf: url) else {
                        print("Couldn't extract data from url: \(url)")
                        continue
                    }
                    let file = File(
                        id: state.files.count,
                        name: url.lastPathComponent,
                        type: .file,
                        data: data
                    )
                    state.files.append(file)
                }
                
            case .internal(.showFiles):
                state.isLoading = false
                return .send(.delegate(.filesHasBeenUploaded))
            }
            
            return .none
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

// MARK: - View

@ViewAction(for: FormUploadBoxFeature.self)
struct FormUploadBoxRow: View {
    
    // MARK: - Properties
    
    @Perception.Bindable var store: StoreOf<FormUploadBoxFeature>
    @Environment(\.tintColor) private var tintColor
    @State private var pickerItem: PhotosPickerItem?
    
    // MARK: - Body
    
    var body: some View {
        WithPerceptionTracking {
            VStack(spacing: 6) {
                FieldSection(
                    title: store.title,
                    description: store.description,
                    required: store.isRequired
                ) {
                    WithPerceptionTracking {
                        if store.files.isEmpty {
                            UploadView()
                        } else {
                            FilesGrid()
                        }
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if !store.files.isEmpty {
                        Button {
                            send(.addMoreButtonTapped)
                        } label: {
                            Label("Add more", systemSymbol: .plus)
                                .font(.footnote)
                                .tint(tintColor)
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
                allowedContentTypes: [.png, .jpeg],
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
                selection: $pickerItem
            )
            .task(id: pickerItem) {
                guard let data = try? await pickerItem?.loadTransferable(type: Data.self) else {
                    return
                }
                if let pickerItem, let localID = pickerItem.itemIdentifier {
                    let result = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                    if let asset = result.firstObject {
                        print("Got " + asset.debugDescription)
                        #warning("Check if its working")
                    }
                }
                send(.photosPickerPhotoSelected(data))
            }
            .tint(tintColor)
        }
    }
    
    // MARK: - Upload View
    
    @ViewBuilder
    private func UploadView() -> some View {
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
    }
    
    // MARK: - Files Grid
    
    @ViewBuilder
    private func FilesGrid() -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(store.files) { file in
                    FileView(file)
                }
            }
        }
        .scrollIndicators(.hidden)
        .animation(.default, value: store.files)
    }
    
    // MARK: - File View
    
    @ViewBuilder
    private func FileView(_ file: FormUploadBoxFeature.File) -> some View {
        VStack(spacing: 0) {
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

#Preview("Upload Box (Empty)") {
    FormUploadBoxRow(
        store: Store(
            initialState: FormUploadBoxFeature.State(
                id: 0,
                title: "File skin",
                description: "Supported formats: jpg, jpeg, gif, png",
                flag: 1,
                allowedExtensions: ["jpg", "jpeg", "gif", "png"]
            )
        ) {
            FormUploadBoxFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}

#Preview("Upload Box (Filled, 3)") {
    FormUploadBoxRow(
        store: Store(
            initialState: FormUploadBoxFeature.State(
                id: 0,
                title: "File skin",
                description: "Supported formats: jpg, jpeg, gif, png",
                flag: 1,
                allowedExtensions: ["jpg", "jpeg", "gif", "png"],
                files: [
                    .init(id: 0, name: "File 1", type: .file, data: Data()),
                    .init(id: 1, name: "Image 1", type: .image, data: Data()),
                    .init(id: 2, name: "File 2", type: .file, data: Data()),
                ]
            )
        ) {
            FormUploadBoxFeature()
        }
    )
    .padding(.horizontal, 16)
    .environment(\.tintColor, Color(.Theme.primary))
}
