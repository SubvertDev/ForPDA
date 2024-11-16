//
//  UnreadParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import Foundation
import Models

public struct UnreadParser {
    public static func parse(rawString string: String) throws -> Unread {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return Unread(
                    date: Date(timeIntervalSince1970: array[2] as! TimeInterval),
                    unreadCount: array[3] as! Int,
                    items: parseItem(array[6] as! [[Any]])
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseItem(_ array: [[Any]]) -> [Unread.Item] {
        return array.compactMap { unread in
            if unread.isEmpty { return nil }
            return Unread.Item(
                id: unread[1] as! Int,
                name: unread[2] as! String,
                authorId: unread[3] as! Int,
                authorName: unread[4] as! String,
                lastMessageId: unread[5] as! Int,
                unreadCount: unread[7] as! Int,
                category: itemCategory(unread[0] as! Int)
            )
        }
    }
    
    private static func itemCategory(_ id: Int) -> Unread.Item.Category {
        return switch id {
        case 1:  Unread.Item.Category.qms
        case 2:  Unread.Item.Category.forum
        case 4:  Unread.Item.Category.forumMention
        case 5:  Unread.Item.Category.siteMention
        default: Unread.Item.Category.topic
        }
    }
}
