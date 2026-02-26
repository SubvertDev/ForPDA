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
    
    // MARK: - Localization
    
    public enum Localization {
        static let badFileSize = LocalizedStringResource("Incorrect size", bundle: .module)
        static let fileSizeTooBig = LocalizedStringResource("File size too big", bundle: .module)
        static let badFileExtension = LocalizedStringResource("Sorry, this format is not supported", bundle: .module)
        static let unknownUploadError = LocalizedStringResource("Sorry, unknown error occured", bundle: .module)
        static let selectAnotherFile = LocalizedStringResource("Select another file. If there are already files in the queue, it will be uploaded last", bundle: .module)
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
        
        var uploadQueue: [UploadBoxFile.FileSource] = []
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
            case fileButtonTapped(_ serverId: Int, _ name: String)
            case fileWithErrorButtonTapped(_ id: UUID)
            case selectFilesButtonTapped
            case removeFileButtonTapped(UploadBoxFile)
            case photosPickerPhotosSelected([UploadBoxFile.FileSource])
            case fileImporterURLsRecieved([URL])
            case fileImporterURLsRecievingFailure
            
            case fileUploadCanceled(UUID?, UploadBoxFile.UploadErrorType)
        }
        
        case `internal`(Internal)
        public enum Internal {
            case startNextUpload
            case uploadFile(UploadBoxFile)
            case uploadFileFinished(index: Int, Int)
            case updateFileUploadStatus(UUID, UploadProgressStatus)
        }
        
        case delegate(Delegate)
        public enum Delegate {
            case someFileUploading
            case allFilesAreUploaded
            case fileHasBeenRemoved(Int)
            case fileHasBeenUploaded(Int)
            
            case fileHasBeenTapped(Int, String)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Cancellable
    
    private enum CancelID: Hashable { case uploading }
    
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
                        [.image(url: URL(string: "")!, ext: nil)]
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
                if let index = state.files.firstIndex(where: { $0.id == id }),
                   let fileSource = state.files[index].fileSource {
                    state.uploadQueue.append(fileSource)
                    if !state.isAnyFileUploading && state.uploadQueue.count == 1 {
                        return .concatenate(
                            .send(.view(.removeFileButtonTapped(state.files[index]))),
                            .send(.internal(.startNextUpload))
                        )
                    } else {
                        return .send(.view(.removeFileButtonTapped(state.files[index])))
                    }
                }
                
            case .destination:
                break
                
            case let .view(.fileButtonTapped(id, name)):
                return .send(.delegate(.fileHasBeenTapped(id, name)))
                
            case let .view(.fileWithErrorButtonTapped(id)):
                if let index = state.files.firstIndex(where: { $0.id == id }),
                   let error = state.files[index].uploadingError {
                    return .send(.view(.fileUploadCanceled(id, error)))
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
                    return .concatenate(
                        .cancel(id: CancelID.uploading),
                        .send(.internal(.startNextUpload))
                        // no need to send delegate .fileHasBeenRemoved,
                        // cause file at level upper not exists (cause not uploaded)
                    )
                }
                if let serverId = file.serverId { // file already uploaded
                    return .send(.delegate(.fileHasBeenRemoved(serverId)))
                }
                
            case let .view(.photosPickerPhotosSelected(images)):
                if isPreview {
                    state.files.append(.mockImage)
                    return .send(.delegate(.fileHasBeenUploaded(0)))
                }
                state.uploadQueue.append(contentsOf: images)
                return .send(.internal(.startNextUpload))
                
            case let .view(.fileImporterURLsRecieved(urls)):
                if isPreview {
                    state.files.append(.mockFile)
                    return .send(.delegate(.fileHasBeenUploaded(0)))
                }
                state.uploadQueue.append(contentsOf: urls.map { .file(url: $0) })
                return .send(.internal(.startNextUpload))
                
            case .view(.fileImporterURLsRecievingFailure):
                state.destination = .alert(.fileImportFailed)
                
            case let .view(.fileUploadCanceled(id, reason)):
                switch reason {
                case .sizeTooBig:
                    state.destination = .alert(.criticalFileConfirmation(
                        fileId: id,
                        title: TextState(Localization.fileSizeTooBig),
                        message: TextState(Localization.selectAnotherFile)
                    ))
                case .badExtension:
                    state.destination = .alert(.criticalFileConfirmation(
                        fileId: id,
                        title: TextState(Localization.badFileExtension),
                        message: TextState(Localization.selectAnotherFile)
                    ))
                case .emptyFileData:
                    state.destination = .alert(.criticalFileConfirmation(
                        fileId: id,
                        title: TextState(Localization.badFileSize),
                        message: TextState(Localization.selectAnotherFile)
                    ))
                case .other(let error):
                    state.destination = .alert(.criticalFileConfirmation(
                        fileId: id,
                        title: TextState(Localization.unknownUploadError),
                        message: TextState(verbatim: error.description)
                    ))
                case .uploadFailure:
                    if let id {
                        state.destination = .alert(.reuploadFileConfirmation(id: id))
                    }
                case .noAccessToSSR:
                    state.destination = .alert(.noAccessToSecurityScopedResource)
                }
                
            case .internal(.startNextUpload):
                guard let item = state.uploadQueue.first else {
                    state.isAnyFileUploading = false
                    return .send(.delegate(.allFilesAreUploaded))
                }
                
                state.isAnyFileUploading = true
                state.uploadQueue.removeFirst()
                
                let url: URL
                let name: String
                let uploadType: UploadBoxFile.FileType
                let fileExtension: String?
                
                switch item {
                case .file(let u):
                    url = u
                    name = url.lastPathComponent
                    uploadType = .file
                    fileExtension = url.pathExtension
                case .image(let u, let ext):
                    url = u
                    uploadType = .image
                    fileExtension = ext
                    name = "\(UUID().uuidString).\(fileExtension ?? "bin")"
                }
                
                guard let ext = fileExtension, fileExtensionAllowed(ext, state.allowedExtensions) else {
                    return .concatenate(
                        .send(.view(.fileUploadCanceled(nil, .badExtension))),
                        .send(.internal(.startNextUpload))
                    )
                }
                
                let file = UploadBoxFile(
                    name: name,
                    type: uploadType,
                    url: url,
                    isUploading: true,
                    fileSource: item
                )
                state.files.append(file)
                
                return .send(.internal(.uploadFile(file)))
                
            case let .internal(.uploadFile(file)):
                state.isAnyFileUploading = true
                
                return .run(priority: .userInitiated, name: file.name) { send in
                    if file.type == .file {
                        guard file.url.startAccessingSecurityScopedResource() else {
                            await send(.view(.fileUploadCanceled(file.id, .noAccessToSSR)))
                            await send(.internal(.startNextUpload))
                            return
                        }
                    }
                    
                    let data = try? Data(contentsOf: file.url)
                    
                    if file.type == .file {
                        file.url.stopAccessingSecurityScopedResource()
                    }
                    
                    guard let data else {
                        await send(.view(.fileUploadCanceled(file.id, .emptyFileData)))
                        await send(.internal(.startNextUpload))
                        return
                    }
                    
                    let request = UploadRequest(
                        fileName: file.name,
                        fileData: data,
                        isQms: false
                    )
                    
                    await send(.delegate(.someFileUploading))
                    
                    for await status in apiClient.upload(request) {
                        await send(.internal(.updateFileUploadStatus(file.id, status)))
                    }
                }
                .cancellable(id: CancelID.uploading)
                
            case let .internal(.updateFileUploadStatus(id, status)):
                guard let index = state.files.firstIndex(where: { $0.id == id }) else { break }
                switch status {
                case let .done(response):
                    guard let fileId = Int(response.replacingOccurrences(of: "[", with: "")
                        .replacingOccurrences(of: "]", with: "")
                        .components(separatedBy: ",")[2]) else {
                        break
                    }
                    return .send(.internal(.uploadFileFinished(index: index, fileId)))
                    
                case .uploading:
                    break
                    
                case let .initialized(md5, _):
                    guard (state.files.firstIndex(where: { !$0.isUploading && $0.md5 == md5 }) == nil) else {
                        // file already uploaded - remove this duplicate
                        return .send(.view(.removeFileButtonTapped(state.files[index])))
                    }
                    state.files[index].md5 = md5
                    return .none
                    
                case let .error(error):
                    state.files[index].uploadingError = switch error {
                    case .serverDenied: .uploadFailure
                    case .fileSizeTooBig: .sizeTooBig
                    case .fileNotAllowed, .fileTypeNotAllowed: .badExtension
                    case .responseStatus: .uploadFailure
                    case .other(let error): .other(error as NSError)
                    @unknown default: .uploadFailure
                    }
                    state.files[index].isUploading = false
                    
                @unknown default:
                    print("UNKNOWN DEFAULT ERROR! \(id), \(status)")
                    state.files[index].isUploading = false
                    state.files[index].uploadingError = .uploadFailure
                }
                return .send(.internal(.startNextUpload))
                
            case let .internal(.uploadFileFinished(index, responseFileId)):
                state.files[index].serverId = responseFileId
                state.files[index].fileSource = nil
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
                TextState("You can try uploading it again. If there are already files in the queue, it will be uploaded last", bundle: .module)
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
    
    nonisolated(unsafe) static let fileImportFailed = AlertState {
        TextState("File import failed. Please, try again", bundle: .module)
    } actions: {
        ButtonState {
            TextState("OK")
        }
    }
    
    nonisolated(unsafe) static let noAccessToSecurityScopedResource = AlertState {
        TextState("Unable to access security scoped resource")
    } actions: {
        ButtonState {
            TextState("OK")
        }
    }
}

// MARK: - Helpers

private extension UploadBoxFeature {
    func fileExtensionAllowed(_ ext: String?, _ allowed: [String]) -> Bool {
        guard let fileExtension = ext else { return false }
        guard !allowed.isEmpty else { return true }
        for allowedExtension in allowed {
            if fileExtension.lowercased() == allowedExtension.lowercased() {
                return true
            }
        }
        return false
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
