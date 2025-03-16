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
    
    private static func parseItems(_ itemsRaw: [[Any]]) throws(ParsingError) -> [Unread.Item] {
        var items: [Unread.Item] = []
        for item in itemsRaw {
            guard !item.isEmpty else {
                continue
            }
            
            guard let category = item[safe: 0] as? Int,
                  let id = item[safe: 1] as? Int,
                  let name = item[safe: 2] as? String,
                  let authorId = item[safe: 3] as? Int,
                  let authorName = item[safe: 4] as? String,
                  let timestamp = item[safe: 5] as? Int,
                  let unreadCount = item[safe: 7] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            guard let category = Unread.Item.Category(rawValue: category) else {
                throw ParsingError.failedToCastFields
            }
            
            let item = Unread.Item(
                id: id,
                name: name,
                authorId: authorId,
                authorName: authorName,
                timestamp: timestamp,
                unreadCount: unreadCount, // unread for qms, notification type for others
                category: category
            )
            items.append(item)
        }
        return items
    }
}
