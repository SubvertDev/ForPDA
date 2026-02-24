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
    public let md5: String
    public var isUploading: Bool
    public var uploadingError: UploadErrorType?
    public var serverId: Int?
    
    var fileSource: FileSource? = nil // for reupload
    
    public enum FileType: Sendable, Equatable {
        case file, image
    }
    
    public enum FileSource: Equatable, Hashable, Sendable {
        case file(url: URL)
        case image(data: Data, ext: String?)
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
        md5: String,
        isUploading: Bool = false,
        uploadingError: UploadErrorType? = nil,
        serverId: Int? = nil,
        fileSource: FileSource? = nil
    ) {
        self.name = name
        self.type = type
        self.data = data
        self.md5 = md5
        self.isUploading = isUploading
        self.uploadingError = uploadingError
        self.serverId = serverId
        self.fileSource = fileSource
    }
}

extension UploadBoxFile {
    static let mockImage = UploadBoxFile(
        name: UUID().uuidString,
        type: .image,
        data: Data(),
        md5: UUID().uuidString,
        serverId: 0
    )
    
    static let mockFile = UploadBoxFile(
        name: UUID().uuidString,
        type: .file,
        data: Data(),
        md5: UUID().uuidString,
        serverId: 1
    )
}
