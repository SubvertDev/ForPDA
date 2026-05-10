//
//  TicketParser.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

import Foundation
import Models

public struct TicketParser {
    
    // MARK: - Ticket Response
    
    public static func parse(from string: String) throws(ParsingError) -> Ticket {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let title = array[safe: 3] as? String,
              let subjectId = array[safe: 14] as? Int,
              let subjectElementId = array[safe: 15] as? Int,
              let subjectRootId = array[safe: 4] as? Int,
              let subjectRootName = array[safe: 5] as? String,
              let createdAt = array[safe: 6] as? Int,
              let processedAt = array[safe: 7] as? Int,
              let authorId = array[safe: 8] as? Int,
              let authorName = array[safe: 9] as? String,
              let handlerId = array[safe: 10] as? Int,
              let handlerName = array[safe: 11] as? String,
              let commentsRaw = array[safe: 13] as? [[Any]],
              let statusRaw = array[safe: 0] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        return Ticket(
            info: TicketInfo(
                title: title,
                status: TicketStatus(rawValue: statusRaw)!,
                subjectId: subjectId,
                subjectElementId: subjectElementId,
                subjectRootId: subjectRootId,
                subjectRootName: subjectRootName.convertCodes(),
                authorId: authorId,
                authorName: authorName.convertCodes(),
                handlerId: handlerId,
                handlerName: handlerName.convertCodes(),
                createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt)),
                processedAt: processedAt != 0 ? Date(timeIntervalSince1970: TimeInterval(processedAt)) : nil
            ),
            comments: try parseComments(commentsRaw)
        )
    }
    
    // MARK: - Ticket Comments
    
    private static func parseComments(_ commentsRaw: [[Any]]) throws(ParsingError) -> [Ticket.Comment] {
        var comments: [Ticket.Comment] = []
        for comment in commentsRaw {
            guard let id = comment[safe: 0] as? Int,
                  let content = comment[safe: 4] as? String,
                  let authorId = comment[safe: 2] as? Int,
                  let authorName = comment[safe: 3] as? String,
                  let createdAt = comment[safe: 1] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            comments.append(.init(
                id: id,
                content: content,
                authorId: authorId,
                authorName: authorName.convertCodes(),
                createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt))
            ))
        }
        return comments
    }
    
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
        
        return TicketsList(
            tickets: try parseTicketsInfo(ticketsRaw),
            availableCount: availableCount
        )
    }
    
    // MARK: - Tickets Info
    
    private static func parseTicketsInfo(_ infoRaw: [[Any]]) throws(ParsingError) -> [TicketsList.TicketSimplified] {
        var ticketsInfo: [TicketsList.TicketSimplified] = []
        for info in infoRaw {
            guard let id = info[safe: 0] as? Int,
                  let title = info[safe: 2] as? String,
                  let subjectId = info[safe: 12] as? Int,
                  let subjectElementId = info[safe: 13] as? Int,
                  let subjectRootId = info[safe: 3] as? Int,
                  let subjectRootName = info[safe: 4] as? String,
                  let createdAt = info[safe: 5] as? Int,
                  let processedAt = info[safe: 6] as? Int,
                  let authorId = info[safe: 7] as? Int,
                  let authorName = info[safe: 8] as? String,
                  let handlerId = info[safe: 9] as? Int,
                  let handlerName = info[safe: 10] as? String,
                  let statusRaw = info[safe: 1] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            ticketsInfo.append(.init(
                id: id,
                info: TicketInfo(
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
                    createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt)),
                    processedAt: processedAt != 0 ? Date(timeIntervalSince1970: TimeInterval(processedAt)) : nil
                )
            ))
        }
        return ticketsInfo
    }
    
    // MARK: - Ticket Status Change Response
    
    public static func parseChangeTicketStatus(from string: String) throws(ParsingError) -> TicketStatusChangeResponse {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let status = array[safe: 0] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        switch status {
        case 0:
            return .success
            
        case 4:
            guard let handlerId = array[safe: 1] as? Int,
                  let handlerName = array[safe: 2] as? String else {
                throw ParsingError.failedToCastFields
            }
            return .failure(.handlerChanged(id: handlerId, name: handlerName))
            
        default:
            return .failure(.other)
        }
    }
    
    // MARK: - Ticket Status History Response
    
    public static func parseTicketStatusHistory(from string: String) throws(ParsingError) -> [TicketStatusHistory] {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let statusRaw = array[safe: 0] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return try! statusRaw.map { status in
            guard let status = array[safe: 0] as? Int,
                  let handlerId = array[safe: 2] as? Int,
                  let handlerName = array[safe: 3] as? String,
                  let changedAt = array[safe: 1] as? Int else {
                throw ParsingError.failedToCastFields
            }
            
            return TicketStatusHistory(
                status: TicketStatus(rawValue: status)!,
                handlerId: handlerId,
                handlerName: handlerName.convertCodes(),
                changedAt: Date(timeIntervalSince1970: TimeInterval(changedAt))
            )
        }
    }
}
