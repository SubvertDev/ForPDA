//
//  SearchParser.swift
//  ForPDA
//
//  Created by Рустам Ойтов on 19.08.2025.
//

import Foundation
import Models
import ComposableArchitecture

public struct SearchParser {
    
    // MARK: - SearchResponse
    
    public static func parse(from string: String) throws(ParsingError) -> SearchResponse {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let metadata0 = array[safe: 0] as? Int,
              let metadata1 = array[safe: 1] as? Int,
              let metadata2 = array[safe: 2] as? Int,
              let publications = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return SearchResponse(
            metadata: [metadata0, metadata1, metadata2],
            publications: try parseSearch(publications)
        )
    }
    
    // MARK: - Publications
    
    private static func parseSearch(_ publicationsRaw: [[Any]]) throws(ParsingError) -> [Publication] {
        var publications: [Publication] = []
        for publication in publicationsRaw {
            guard let unknownValue1 = publication[safe: 0] as? Int,
                  let unknownValue2 = publication[safe: 1] as? Int,
                  let unknownValue3 = publication[safe: 2] as? Int,
                  let postName = publication[safe: 3] as? String,
                  let messageId = publication[safe: 4] as? Int,
                  let unknownValue4 = publication[safe: 5] as? Int,
                  let unknownValue5 = publication[safe: 6] as? Int,
                  let authorName = publication[safe: 7] as? String,
                  let unknownValue6 = publication[safe: 8] as? Int,
                  let unknownValue7 = publication[safe: 9] as? Int,
                  let authorReputation = publication[safe: 10] as? Int,
                  let timestamp = publication[safe: 11] as? TimeInterval,
                  let text = publication[safe: 12] as? String,
                  let authorAvatar = publication[safe: 13] as? String,
                  let signatureAuthor = publication[safe: 14] as? String,
                  let unknownValue10 = publication[safe: 16] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            let publication = Publication(
                unknownValue1: unknownValue1,
                unknownValue2: unknownValue2,
                unknownValue3: unknownValue3,
                postName: postName.convertCodes(),
                messageId: messageId,
                unknownValue4: unknownValue4,
                unknownValue5: unknownValue5,
                authorName: authorName.convertCodes(),
                unknownValue6: unknownValue6,
                unknownValue7: unknownValue7,
                authorReputation: authorReputation,
                date: Date(timeIntervalSince1970: timestamp),
                text: text.convertCodes(),
                authorAvatar: authorAvatar,
                signatureAuthor: signatureAuthor.convertCodes(),
                unknownValue10: unknownValue10
            )
            publications.append(publication)
        }
        return publications
    }
}
