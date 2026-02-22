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
    public var isUploadError: Bool
    
    public enum FileType: Sendable {
        case file, image
    }
    
    public init(
        name: String,
        type: FileType,
        data: Data,
        isUploading: Bool = false,
        isUploadError: Bool = false
    ) {
        self.name = name
        self.type = type
        self.data = data
        self.isUploading = isUploading
        self.isUploadError = isUploadError
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
