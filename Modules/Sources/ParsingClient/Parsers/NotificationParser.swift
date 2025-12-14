//
//  NotificationParser.swift
//  ParsingClient
//
//  Created by Ilia Lubianoi on 05.10.2025.
//

import Foundation
import Models

public struct NotificationParser {
    
    public static func parse(from string: String) throws(ParsingError) -> EventNotification {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let string = array[safe: 2] as? String,
              let letter = string.first,
              let id = Int(string.dropFirst()),
              let flag = array[safe: 3] as? Int,
              let timestamp = array[safe:4] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        let category = EventNotification.Category(rawValue: String(letter)) ?? .unknown
        
        return EventNotification(
            id: id,
            category: category,
            flag: flag,
            timestamp: timestamp
        )
    }
}
