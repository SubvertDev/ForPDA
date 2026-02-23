//
//  UploadBoxFile.swift
//  ForPDA
//
//  Created by Xialtal on 2.01.26.
//

import Foundation

public struct UploadBoxFile: Sendable, Identifiable, Equatable {
    public let id = UUID()
    public let name: String
    public let type: FileType
    public let data: Data
    public var isUploading: Bool
    public var uploadingError: UploadErrorType?
    
    public var serverId: Int? = nil
    
    public enum FileType: Sendable, Equatable {
        case file, image
    }
    
    public enum UploadErrorType: Sendable {
        case sizeTooBig
        case badExtension
        case uploadFailure
    }
    
    public init(
        name: String,
        type: FileType,
        data: Data,
        isUploading: Bool = false,
        uploadingError: UploadErrorType? = nil
    ) {
        self.name = name
        self.type = type
        self.data = data
        self.isUploading = isUploading
        self.uploadingError = uploadingError
    }
}

extension UploadBoxFile {
    static let mockImage = UploadBoxFile(
        name: UUID().uuidString,
        type: .image,
        data: Data()
    )
    
    static let mockFile = UploadBoxFile(
        name: UUID().uuidString,
        type: .file,
        data: Data()
    )
}
