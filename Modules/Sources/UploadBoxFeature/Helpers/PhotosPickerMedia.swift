//
//  PhotosPickerMedia.swift
//  ForPDA
//
//  Created by Xialtal on 25.02.26.
//

import SwiftUI

struct PhotosPickerMedia: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .item) { media in
            SentTransferredFile(media.url)
        } importing: { received in
            return try await PhotosPickerMedia(
                url: loadFileToTempDirectory(received.file)
            )
        }
    }
    
    private static func loadFileToTempDirectory(_ url: URL) async throws -> URL {
        try await Task.detached(priority: .utility) {
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString)")
            
            try FileManager.default.copyItem(at: url, to: fileURL)
            
            return fileURL
        }.value
    }
}

