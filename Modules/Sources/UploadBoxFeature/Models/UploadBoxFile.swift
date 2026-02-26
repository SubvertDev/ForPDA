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
    public let url: URL
    public var md5: String?
    public var isUploading: Bool
    public var uploadingError: UploadErrorType?
    public var serverId: Int?
    
    var fileSource: FileSource? = nil // for reupload
    
    public enum FileType: Sendable, Equatable {
        case file, image
    }
    
    public enum FileSource: Equatable, Hashable, Sendable {
        case file(url: URL)
        case image(url: URL, ext: String?)
    }
    
    public enum UploadErrorType: Sendable, Equatable {
        case sizeTooBig
        case badExtension
        case uploadFailure
        
        case noAccessToSSR
        case emptyFileData
        case other(NSError)
    }
    
    public init(
        name: String,
        type: FileType,
        url: URL,
        md5: String? = nil,
        isUploading: Bool = false,
        uploadingError: UploadErrorType? = nil,
        serverId: Int? = nil,
        fileSource: FileSource? = nil
    ) {
        self.name = name
        self.type = type
        self.url = url
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
        url: URL(string: "")!,
        md5: UUID().uuidString,
        serverId: 0
    )
    
    static let mockFile = UploadBoxFile(
        name: UUID().uuidString,
        type: .file,
        url: URL(string: "")!,
        md5: UUID().uuidString,
        serverId: 1
    )
}
