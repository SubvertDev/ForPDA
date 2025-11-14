//
//  AttachmentParser.swift
//  ForPDA
//
//  Created by Xialtal on 14.11.25.
//

import Foundation
import Models

struct AttachmentParser {
    
    // MARK: - Article
    
    /**
    0. 1 - id
    1. "https..." - small image url
    2. 480 - width
    3. 300 - height
    4. "description" - description
    5. "https..." - (optional) full image url
    */
    static func parseArticleAttachment(from array: [[Any]]) -> [Attachment] {
        return array.map { fields in
            return Attachment(
                id: fields[0] as! Int,
                type: .image,
                name: "",
                size: 0,
                metadata: .init(
                    width: fields[2] as! Int,
                    height: fields[3] as! Int,
                    url: URL(string: fields[1] as! String)!,
                    fullUrl: URL(string: fields[5] as! String)
                ),
                downloadCount: nil
            )
        }
    }
    
    // MARK: - Forum
    
    static func parseAttachment(_ attachmentsRaw: [[Any]]) throws(ParsingError) -> [Attachment] {
        var attachments: [Attachment] = []
        for attachment in attachmentsRaw {
            guard let id = attachment[safe: 0] as? Int,
                  let type = attachment[safe: 1] as? Int,
                  let name = attachment[safe: 2] as? String,
                  let size = attachment[safe: 3] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            guard let type = Attachment.AttachmentType(rawValue: type) else {
                throw ParsingError.unknownAttachmentType(type)
            }
            
            let downloadCount = (attachment[safe: 7] as? Int) ?? (attachment[safe: 4] as? Int)
            
            let attachment = Attachment(
                id: id,
                type: type,
                name: name,
                size: size,
                metadata: try parseAttachmentMetadata(attachment),
                downloadCount: downloadCount // Only if attachment.count > 7
            )
            attachments.append(attachment)
        }
        return attachments
    }
    
    // MARK: - Attachment Metadata
     
    private static func parseAttachmentMetadata(_ attachment: [Any]) throws(ParsingError) -> Attachment.Metadata? {
        if attachment.count <= 5 {
            return nil
        }
        
        guard let url = attachment[safe: 4] as? String,
              let width = attachment[safe: 5] as? Int,
              let height = attachment[safe: 6] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        guard let url = URL(string: url) else {
            throw ParsingError.failedToCreateAttachmentMetadataUrl
        }
        
        return Attachment.Metadata(
            width: width,
            height: height,
            url: url
        )
    }
}
