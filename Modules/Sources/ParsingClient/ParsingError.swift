//
//  ParsingError.swift
//  
//
//  Created by Ilia Lubianoi on 07.07.2024.
//

import Foundation

enum ParsingError: Error {
    case failedToCreateDataFromString
    case failedToSerializeData(any Error)
    case failedToCastDataToAny
    
    case failedToExtractImage
    case failedToExtractImages
    case failedToExtractVideo
    case failedToExtractAdvertisment
}
