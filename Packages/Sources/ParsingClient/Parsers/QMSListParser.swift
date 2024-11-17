//
//  QMSListParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import Models

public struct QMSListParser {
    public static func parse(rawString string: String) throws -> QMSList {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return QMSList(users: parseUsers(array[2] as! [[Any]]))
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseUsers(_ array: [[Any]]) -> [QMSUser] {
        return array.map { user in
            return QMSUser(
                userId: user[0] as! Int,
                name: user[1] as! String,
                flag: user[2] as! Int,
                avatarUrl: URL(string: user[3] as! String),
                lastSeenOnline: Date(timeIntervalSince1970: user[4] as! TimeInterval),
                lastMessageDate: Date(timeIntervalSince1970: user[5] as! TimeInterval),
                unreadCount: user[6] as! Int,
                chats: parseChats(user[7] as! [[Any]])
            )
        }
    }
    
    private static func parseChats(_ array: [[Any]]) -> [QMSChatInfo] {
        return array.map { chat in
            return QMSChatInfo(
                id: chat[0] as! Int,
                creationDate: Date(timeIntervalSince1970: chat[1] as! TimeInterval),
                lastMessageDate: Date(timeIntervalSince1970: chat[2] as! TimeInterval),
                name: chat[3] as! String,
                totalCount: chat[4] as! Int,
                unreadCount: chat[5] as! Int,
                lastMessageId: chat[6] as! Int
            )
        }
    }
}
