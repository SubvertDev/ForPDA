//
//  ParsingError.swift
//  
//
//  Created by Ilia Lubianoi on 07.07.2024.
//

import Foundation

public enum ParsingError: Error {
    // General
    case failedToCreateDataFromString
    case failedToSerializeData(any Error)
    case failedToCastDataToAny
//    case notEnoughDataToParse
    case failedToCastFields
    
    // Topic
    case unknownAttachmentType(Int)
    case failedToCreateAttachmentMetadataUrl
    
    case failedToExtractImage
    case failedToExtractImages
    case failedToExtractVideo
    case failedToExtractAdvertisment
    
    case failedToFindPost
}
