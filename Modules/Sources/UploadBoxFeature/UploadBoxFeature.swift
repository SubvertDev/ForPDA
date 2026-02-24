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
    
    // MARK: - File Type
    
    public enum FileType: Equatable, Hashable, Sendable {
        case file(url: URL)
        case image(data: Data, ext: String?)
    }
    
    // MARK: - Destination
    
    @Reducer
    public enum Destination {
        case confirmationDialog(ConfirmationDialogState<Dialog>)
        case fileImporter
        case photosPicker
        case alert(AlertState<Alert>)
        
        @CasePathable
        public enum Alert: Equatable {
            case removeFile(UUID)
            case reuploadFile(UUID)
            
            case selectFileFromFiles(oldFile: UUID?)
            case selectFileFromGallery(oldFile: UUID?)
        }
        
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
        public var allowedExtensions: [String]
        var files: [UploadBoxFile]
        
        var uploadQueue: [FileType] = []
        var isAnyFileUploading = false
        
        public var filesCount: Int {
            return files.count
        }
        
        public init(
            type: UploadBoxType,
            allowedExtensions: [String] = [],
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
            case onFileButtonTapped(Int)
            case fileWithErrorTapped(UUID)
            case selectFilesButtonTapped
            case removeFileButtonTapped(UploadBoxFile)
            case photosPickerPhotosSelected([FileType])
            case fileImporterURLsRecieved([URL])
        }
        
        case `internal`(Internal)
        public enum Internal {
            case startNextUpload
            case uploadFile(UploadBoxFile)
            case uploadFileFinished(index: Int, Int)
            case updateFileUploadStatus(UUID, UploadProgressStatus)
            case uploadFileCanceledByValidation(UUID?, UploadBoxFile.UploadErrorType)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case someFileUploading
            case allFilesAreUploaded
            case fileHasBeenRemoved(Int)
            case fileHasBeenUploaded(Int)
            
            case fileHasBeenTapped(Int)
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
                    return .send(.view(.photosPickerPhotosSelected(
                        [.image(data: Data(), ext: nil)]
                    )))
                } else {
                    state.destination = .photosPicker
                }
                
            case let .destination(.presented(.alert(.selectFileFromFiles(oldFileId)))):
                if let oldFileId = oldFileId,
                   let oldIndex = state.files.firstIndex(where: { $0.id == oldFileId }) {
                    return .concatenate(
                        .send(.view(.removeFileButtonTapped(state.files[oldIndex]))),
                        .send(.destination(.presented(.confirmationDialog(.files))))
                    )
                }
                return .send(.destination(.presented(.confirmationDialog(.files))))
                
            case let .destination(.presented(.alert(.selectFileFromGallery(oldFileId)))):
                if let oldFileId = oldFileId,
                   let oldIndex = state.files.firstIndex(where: { $0.id == oldFileId }) {
                    return .concatenate(
                        .send(.view(.removeFileButtonTapped(state.files[oldIndex]))),
                        .send(.destination(.presented(.confirmationDialog(.gallery))))
                    )
                }
                return .send(.destination(.presented(.confirmationDialog(.gallery))))
                
            case let .destination(.presented(.alert(.removeFile(id)))):
                if let index = state.files.firstIndex(where: { $0.id == id }) {
                    return .send(.view(.removeFileButtonTapped(state.files[index])))
                }
                
            case let .destination(.presented(.alert(.reuploadFile(id)))):
                break // TODO: Implement
                
            case .destination:
                break
                
            case let .view(.onFileButtonTapped(id)):
                return .send(.delegate(.fileHasBeenTapped(id)))
                
            case let .view(.fileWithErrorTapped(id)):
                if let index = state.files.firstIndex(where: { $0.id == id }),
                   let error = state.files[index].uploadingError {
                    return .send(.internal(.uploadFileCanceledByValidation(id, error)))
                }
                
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
                if let serverId = file.serverId {
                    return .send(.delegate(.fileHasBeenRemoved(serverId)))
                }
                
            case let .view(.photosPickerPhotosSelected(images)):
                if isPreview {
                    state.files.append(.mockImage)
                    return .send(.delegate(.fileHasBeenUploaded(0)))
                }
                let filtered = Array(Set(state.uploadQueue + images))
                state.uploadQueue.append(contentsOf: filtered)
                return .send(.internal(.startNextUpload))
                
            case let .view(.fileImporterURLsRecieved(urls)):
                if isPreview {
                    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = documentsURL.appending(path: "data.dat")
                    try! Data().write(to: fileURL)
                    state.files.append(.mockFile)
                    return .send(.delegate(.fileHasBeenUploaded(0)))
                }
                let filtered = Array(Set(state.uploadQueue + urls.map { .file(url: $0) }))
                state.uploadQueue.append(contentsOf: filtered)
                return .send(.internal(.startNextUpload))
                
            case let .internal(.uploadFileCanceledByValidation(id, status)):
                switch status {
                case .sizeTooBig:
                    state.destination = .alert(.criticalFileConfirmation(
                        fileId: id,
                        title: TextState("File size too big", bundle: .module),
                        message: TextState("Select another file. If there are already files in the queue, it will be uploaded last", bundle: .module)
                    ))
                case .badExtension:
                    state.destination = .alert(.criticalFileConfirmation(
                        fileId: id,
                        title: TextState("Sorry, this format is not supported", bundle: .module),
                        message: TextState("Select another file. If there are already files in the queue, it will be uploaded last", bundle: .module)
                    ))
                case .uploadFailure:
                    if let id {
                        state.destination = .alert(.reuploadFileConfirmation(id: id))
                    }
                }
                
            case .internal(.startNextUpload):
                guard let item = state.uploadQueue.first else {
                    state.isAnyFileUploading = false
                    return .send(.delegate(.allFilesAreUploaded))
                }
                
                state.isAnyFileUploading = true
                state.uploadQueue.removeFirst()
                
                let data: Data?
                let name: String
                let uploadType: UploadBoxFile.FileType
                let fileExtension: String?
                
                switch item {
                case .file(let url):
                    guard url.startAccessingSecurityScopedResource() else {
                        return .send(.internal(.startNextUpload))
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    data = try? Data(contentsOf: url)
                    name = url.lastPathComponent
                    uploadType = .file
                    fileExtension = url.pathExtension
                case .image(let d, let ext):
                    data = d
                    uploadType = .image
                    fileExtension = if let ext = ext { ext } else { d.imageExtension }
                    name = "\(UUID().uuidString).\(fileExtension ?? "bin")"
                }
                
                guard let ext = fileExtension, fileExtensionAllowed(ext: ext, allowed: state.allowedExtensions) else {
                    return .concatenate(
                        .send(.internal(.uploadFileCanceledByValidation(nil, .badExtension))),
                        .send(.internal(.startNextUpload))
                    )
                }
                guard let data else {
                    return .concatenate(
                        .send(.internal(.uploadFileCanceledByValidation(nil, .sizeTooBig))),
                        .send(.internal(.startNextUpload))
                    )
                }
                
                let file = UploadBoxFile(
                    name: name,
                    type: uploadType,
                    data: data,
                    isUploading: true
                )
                return .send(.internal(.uploadFile(file)))
                
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
                    await send(.delegate(.someFileUploading))
                    
                    for await status in apiClient.upload(request) {
                        await send(.internal(.updateFileUploadStatus(file.id, status)))
                    }
                }
                .cancellable(id: CancelID.uploading(file.id), cancelInFlight: true)
                
            case let .internal(.updateFileUploadStatus(id, status)):
                if let index = state.files.firstIndex(where: { $0.id == id }) {
                    switch status {
                    case .done(let response):
                        guard let fileId = Int(response.replacingOccurrences(of: "[", with: "")
                            .replacingOccurrences(of: "]", with: "")
                            .components(separatedBy: ",")[2]) else {
                            state.files[index].isUploading = false
                            state.files[index].uploadingError = .uploadFailure
                            return .send(.internal(.startNextUpload))
                        }
                        return .send(.internal(.uploadFileFinished(index: index, fileId)))
                        
                    case .uploading(let value):
                        print("Reducer UPLAODING: \(value)")
                        state.files[index].isUploading = true
                        
                    case .initialized:
                        print("FILE UPLOADING INITIALIZED")
                        state.files[index].isUploading = true
                        
                    case .error(let error):
                        state.files[index].uploadingError = switch error {
                        case .serverDenied: .uploadFailure
                        case .fileSizeTooBig: .sizeTooBig
                        case .fileNotAllowed, .fileTypeNotAllowed: .badExtension
                        case .responseStatus, .other: .uploadFailure
                        @unknown default: .uploadFailure
                        }
                        state.files[index].isUploading = false
                        // TODO: capture?
                        print("ERROR ON FILE UPLOADING: \(error)")
                        return .send(.internal(.startNextUpload))
                        
                    @unknown default:
                        print("UNKNOWN DEFAULT ERROR! \(id), \(status)")
                        state.files[index].isUploading = false
                        state.files[index].uploadingError = .uploadFailure
                        return .send(.internal(.startNextUpload))
                    }
                } else {
                    // Do nothing... File removed by user.
                }
                return .none
                
            case let .internal(.uploadFileFinished(index, responseFileId)):
                state.files[index].serverId = responseFileId
                state.files[index].isUploading = false
                return .concatenate(
                    .send(.delegate(.fileHasBeenUploaded(responseFileId))),
                    .send(.internal(.startNextUpload))
                )
            }
            
            return .none
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension UploadBoxFeature.Destination.State: Equatable {}

// MARK: - Alert Extension

extension AlertState where Action == UploadBoxFeature.Destination.Alert {
    
    nonisolated static func reuploadFileConfirmation(id: UUID) -> AlertState {
        return AlertState(
            title: { TextState("An error occurred while uploading the file", bundle: .module) },
            actions: {
                ButtonState(action: .reuploadFile(id)) {
                    TextState("Try Again", bundle: .module)
                }
                ButtonState(role: .destructive, action: .removeFile(id)) {
                    TextState("Delete", bundle: .module)
                }
                ButtonState(role: .cancel) {
                    TextState("Cancel", bundle: .module)
                }
            },
            message: {
                TextState("You can try uploading it again. If there are already files in the queue, it will be uploaded last")
            }
        )
    }
    
    nonisolated static func criticalFileConfirmation(fileId: UUID?, title: TextState, message: TextState) -> AlertState {
        return AlertState(
            title: { title },
            actions: {
                ButtonState(action: .selectFileFromGallery(oldFile: fileId)) {
                    TextState("Choose from Gallery", bundle: .module)
                }
                ButtonState(action: .selectFileFromFiles(oldFile: fileId)) {
                    TextState("Choose from Files", bundle: .module)
                }
                ButtonState(role: .cancel) {
                    TextState("Cancel", bundle: .module)
                }
            },
            message: { message }
        )
    }
}

// MARK: - Helpers

private extension UploadBoxFeature {
    func fileExtensionAllowed(ext: String?, allowed: [String]) -> Bool {
        guard let fileExtension = ext else { return false }
        guard !allowed.isEmpty else { return true }
        for allowedExtension in allowed {
            if fileExtension.lowercased() == allowedExtension.lowercased() {
                return true
            }
        }
        return false
    }
    
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
        case 0x52:
            return "webp"
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
