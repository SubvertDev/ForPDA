//
//  UnreadParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import Foundation
import Models

public struct UnreadParser {
    
    public static func parse(from string: String) throws(ParsingError) -> Unread {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let date = array[safe: 2] as? TimeInterval,
                let qmsUnreadCount = array[safe: 3] as? Int,
                let favoritesUnreadCount = array[safe: 4] as? Int,
                let menitionsUnreadCount = array[safe: 5] as? Int,
                let items = array[safe: 6] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }

        return Unread(
            date: Date(timeIntervalSince1970: date),
            qmsUnreadCount: qmsUnreadCount,
            favoritesUnreadCount: favoritesUnreadCount,
            mentionsUnreadCount: menitionsUnreadCount,
            items: try parseItems(items)
        )
    }
    
    private static func parseItems(_ itemsRaw: [[Any]]) throws(ParsingError) -> [PDANotification] {
        var items: [PDANotification] = []
        for item in itemsRaw {
            guard !item.isEmpty else {
                continue
            }
            
            guard let kindRaw = item[safe: 0] as? Int,
                  let kind = PDANotification.Kind(rawValue: kindRaw),
                  let primaryID = item[safe: 1] as? Int,
                  let primaryName = item[safe: 2] as? String,
                  let memberID = item[safe: 3] as? Int,
                  let memberName = item[safe: 4] as? String,
                  let value = item[safe: 5] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            let item = PDANotification(
                kind: kind,
                primaryID: primaryID,
                primaryName: primaryName,
                memberID: memberID,
                memberName: memberName,
                value: value,
                dateValue: item[safe: 6] as? Int,
                extra1: item[safe: 7] as? Int,
                extra2: item[safe: 8] as? Int,
                extra3: item[safe: 9] as? Int
            )
            items.append(item)
        }
        return items
    }
}
