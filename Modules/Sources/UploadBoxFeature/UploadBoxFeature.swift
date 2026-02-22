//
//  UploadBoxFeature.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.26.
//

import SwiftUI
import ComposableArchitecture
import APIClient
import CryptoKit

@Reducer
public struct UploadBoxFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - Helpers
    
    var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    // MARK: - Destination
    
    @Reducer
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
    public struct State: Equatable {
        @Presents public var destination: Destination.State?
        
        let type: UploadBoxType
        let allowedExtensions: [String]
        
        var files: [UploadBoxFile]
        //var uploadQueue: [UUID] = []
        var isAnyFileUploading = false
        
        public var filesCount: Int {
            return files.count
        }
        
        public init(
            type: UploadBoxType,
            allowedExtensions: [String],
            files: [UploadBoxFile] = []
        ) {
            self.type = type
            self.allowedExtensions = allowedExtensions
            self.files = files
        }
    }
    
    // MARK: - Actions
    
    public enum Action: BindableAction, ViewAction {
        case binding(BindingAction<State>)
        case destination(PresentationAction<Destination.Action>)

        case view(View)
        public enum View {
            case selectFilesButtonTapped
            case removeFileButtonTapped(UploadBoxFile)
            case photosPickerPhotoSelected(Data)
            case fileImporterURLsRecieved([URL])
        }
        
        case `internal`(Internal)
        public enum Internal {
            case uploadFile(UploadBoxFile)
            case updateFileUploadStatus(UUID, UploadProgressStatus)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case someFileUploading
            case allFilesAreUploaded
            case filesHasBeenTapped(String)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Cancellable
    
    private enum CancelID: Hashable { case uploading(UUID) }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce<State, Action> { state, action in
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
                
            case .view(.selectFilesButtonTapped):
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
                if file.isUploading {
                    return .cancel(id: CancelID.uploading(file.id))
                }
                
            case let .view(.photosPickerPhotoSelected(data)):
                if !isPreview {
                    if let imageExtension = data.imageExtension {
                        let file = UploadBoxFile(
                            name: "\(UUID().uuidString).\(imageExtension)",
                            type: .image,
                            data: data
                        )
                        return .send(.internal(.uploadFile(file)))
                    } else {
                        // TODO: send error alert
                    }
                } else {
                    state.files.append(.mockImage)
                }
                
            case let .view(.fileImporterURLsRecieved(urls)):
                //var urls = urls
#warning("Fix preview")
                if isPreview {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsURL.appending(path: "data.dat")
                    try! Data().write(to: fileURL)
                    //urls.append(fileURL)
                    state.files.append(.mockFile)
                    return .none
                }
                return .run { [urls = urls] send in
                    for url in urls {
                        if url.startAccessingSecurityScopedResource() {
                            guard let data = try? Data(contentsOf: url) else {
                                // TODO: Add alert
                                print("Couldn't extract data from url: \(url)")
                                continue
                            }
                            url.stopAccessingSecurityScopedResource()
                            
                            let file = UploadBoxFile(
                                name: url.lastPathComponent,
                                type: .file,
                                data: data,
                                isUploading: true
                            )
                            await send(.internal(.uploadFile(file)))
                            
                            while file.isUploading { /* waiting... */ }
                        } else {
                            print("=============== NO ACCESS ================")
                        }
                    }
                }
                
            case let .internal(.uploadFile(file)):
                state.files.append(file)
                state.isAnyFileUploading = true
                return .run(priority: .userInitiated) { [file = file] send in
                    let request = UploadRequest(
                        fileName: file.name,
                        fileSize: file.data.count,
                        fileData: file.data,
                        md5: calculateFileHash(data: file.data),
                        isQms: false
                    )
                    for await status in apiClient.upload(request) {
                        await send(.internal(.updateFileUploadStatus(file.id, status)))
                    }
                }
                .cancellable(id: CancelID.uploading(file.id), cancelInFlight: true)
                
            case let .internal(.updateFileUploadStatus(id, status)):
                if let index = state.files.firstIndex(where: { $0.id == id }) {
                    switch status {
                    case .done(let response):
                        print("YEY<<<<<<< \(response)")
                        state.files[index].isUploading = false
                        state.isAnyFileUploading = false
                    case .uploading(let value):
                        print("Reducer UPLAODING: \(value)")
                        state.files[index].isUploading = true
                    case .initialized:
                        print("FILE UPLOADING INITIALIZED")
                        state.files[index].isUploading = true
                    case .error(let err):
                        // TODO: Alert?
                        print("ERROR ON FILE UPLOADING: \(err)")
                        state.files[index].isUploading = false
                        state.files[index].isUploadError = true
                    @unknown default:
                        print("UNKNOWN DEFAULT ERROR! \(id), \(status)")
                        state.files[index].isUploading = false
                        state.files[index].isUploadError = true
                    }
                } else {
                    // TODO: Handle error.
                }
                return .none
            }
            
            return .none
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension UploadBoxFeature.Destination.State: Equatable {}

// MARK: - Helpers

private extension UploadBoxFeature {
    func calculateFileHash(data: Data) -> String {
        return Insecure.MD5.hash(data: data)
            .map { byte in String(format: "%02X", byte) }
            .joined()
    }
}

private extension Data {
    var imageExtension: String? {
        switch mimeType {
        case 0xFF:
            return "jpeg"
        case 0x89:
            return "png"
        case 0x47:
            return "gif"
        case 0x49, 0x4D:
            return "tiff"
        default:
            return nil
        }
    }
    
    private var mimeType: UInt8 {
        var mt: UInt8 = 0
        copyBytes(to: &mt, count: 1)
        return mt
    }
}
