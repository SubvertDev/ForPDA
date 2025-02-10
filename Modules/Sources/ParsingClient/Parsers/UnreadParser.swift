//
//  UnreadParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import Foundation
import Models

public struct UnreadParser {
    public static func parse(from string: String) throws -> Unread {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return Unread(
                    date: Date(timeIntervalSince1970: array[2] as! TimeInterval),
                    qmsUnreadCount: array[3] as! Int,
                    favoritesUnreadCount: array[4] as! Int,
                    mentionsUnreadCount: array[5] as! Int,
                    items: parseItems(array[6] as! [[Any]])
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseItems(_ array: [[Any]]) -> [Unread.Item] {
        return array.compactMap { unread in
            if unread.isEmpty { return nil }
            return Unread.Item(
                id: unread[1] as! Int,
                name: unread[2] as! String,
                authorId: unread[3] as! Int,
                authorName: unread[4] as! String,
                timestamp: unread[5] as! Int,
                unreadCount: unread[7] as! Int,
                category: Unread.Item.Category(rawValue: unread[0] as! Int)!
            )
        }
    }
}
