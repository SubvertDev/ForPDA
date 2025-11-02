//
//  QMSParser.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 17.11.2024.
//

import Foundation
import Models

public struct QMSChatParser {
    public static func parse(from string: String) throws -> QMSChat {
        if let data = string.data(using: .utf8) {
            do {
                guard let array = try JSONSerialization.jsonObject(with: data, options: []) as? [Any] else { throw ParsingError.failedToCastDataToAny }
                return QMSChat(
                    id: array[2] as! Int,
                    creationDate: Date(timeIntervalSince1970: array[3] as! TimeInterval),
                    lastMessageDate: Date(timeIntervalSince1970: array[4] as! TimeInterval),
                    name: array[5] as! String,
                    partnerId: array[6] as! Int,
                    partnerName: array[7] as! String,
                    flag: array[8] as! Int,
                    avatarUrl: URL(string: array[9] as! String),
                    unknownId1: array[10] as! Int,
                    totalCount: array[11] as! Int,
                    unknownId2: array[12] as! Int,
                    lastMessageId: array[13] as! Int,
                    unreadCount: array[14] as! Int,
                    messages: parseMessages(array[15] as! [[Any]])
                )
            } catch {
                throw ParsingError.failedToSerializeData(error)
            }
        } else {
            throw ParsingError.failedToCreateDataFromString
        }
    }
    
    private static func parseMessages(_ array: [[Any]]) -> [QMSMessage] {
        return array.map { message in
            return QMSMessage(
                id: message[0] as! Int,
                senderId: message[1] as! Int,
                date: Date(timeIntervalSince1970: message[2] as! TimeInterval),
                text: message[3] as! String,
                attachments: parseAttachments(message[4] as! [[Any]])
            )
        }
    }
    
    private static func parseAttachments(_ array: [[Any]]) -> [QMSMessage.Attachment] {
        return array.map { attachment in
            return QMSMessage.Attachment(
                id: attachment[0] as! Int,
                flag: attachment[1] as! Int,
                name: attachment[2] as! String,
                size: attachment[3] as! Int,
                downloadsCount: attachment[4] as! Int
            )
        }
    }
}
