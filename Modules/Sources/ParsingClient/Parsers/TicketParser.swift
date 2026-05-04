//
//  TicketParser.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

import Foundation
import Models

public struct TicketParser {
    
    // MARK: - Tickets List
    
    public static func parseTicketsList(from string: String) throws(ParsingError) -> TicketsList {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let availableCount = array[safe: 2] as? Int,
              let ticketsRaw = array[safe: 3] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return TicketsList(tickets: try parseTicketsInfo(ticketsRaw), availableCount: availableCount)
    }
    
    // MARK: - Tickets Info
    
    private static func parseTicketsInfo(_ infoRaw: [[Any]]) throws(ParsingError) -> [TicketInfo] {
        var ticketsInfo: [TicketInfo] = []
        for info in infoRaw {
            guard let id = info[safe: 0] as? Int,
                  let title = info[safe: 2] as? String,
                  let subjectId = info[safe: 12] as? Int,
                  let subjectElementId = info[safe: 13] as? Int,
                  let subjectRootId = info[safe: 3] as? Int,
                  let subjectRootName = info[safe: 4] as? String,
                  let createdAt = info[safe: 5] as? Int,
                  let authorId = info[safe: 7] as? Int,
                  let authorName = info[safe: 8] as? String,
                  let handlerId = info[safe: 9] as? Int,
                  let handlerName = info[safe: 10] as? String,
                  let statusRaw = info[safe: 14] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            ticketsInfo.append(TicketInfo(
                id: id,
                title: title.convertCodes(),
                status: TicketStatus(rawValue: statusRaw)!,
                subjectId: subjectId,
                subjectElementId: subjectElementId,
                subjectRootId: subjectRootId,
                subjectRootName: subjectRootName.convertCodes(),
                authorId: authorId,
                authorName: authorName.convertCodes(),
                handlerId: handlerId,
                handlerName: handlerName.convertCodes(),
                createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt))
            ))
        }
        return ticketsInfo
    }
}
