//
//  TicketClient.swift
//  ForPDA
//
//  Created by Xialtal on 4.05.26.
//

import APIClient
import Dependencies
import DependenciesMacros
import Foundation
import Models
import PDAPI
import ParsingClient

@DependencyClient
public struct TicketClient: Sendable {
    public var getTicketsList: @Sendable (_ data: TicketsListRequest) async throws -> TicketsList
    public var getTicket: @Sendable (_ id: Int) async throws -> Ticket
    public var getTicketStatusHistory: @Sendable (_ ticketId: Int) async throws -> [TicketStatusHistory]
    public var changeTicketStatus: @Sendable (_ id: Int, _ handlerId: Int, _ status: TicketStatus) async throws -> TicketStatusChangeResponse
    
    public var modifyComment: @Sendable (_ id: Int, _ ticketId: Int, _ text: String) async throws -> Bool
}

extension TicketClient: DependencyKey {
    
    private static var api: API {
        return APIClient.api
    }
    
    // MARK: - Live Value
    
    public static var liveValue: TicketClient {
        @Dependency(\.parsingClient) var parser
        
        return TicketClient(
            getTicketsList: { data in
                let response = try await api.send(TicketCommand.list(
                    forId: data.forId,
                    sortType: data.transferSort,
                    offset: data.offset,
                    limit: data.amount
                ))
                return try await parser.parseTicketsList(response)
            },
            getTicket: { id in
                let response = try await api.send(TicketCommand.view(id: id))
                return try await parser.parseTicket(response)
            },
            getTicketStatusHistory: { ticketId in
                let response = try await api.send(TicketCommand.history(id: ticketId))
                return try await parser.parseTicketStatusHistory(response)
            },
            changeTicketStatus: { ticketId, handlerId, status in
                let response = try await api.send(TicketCommand.modify(
                    id: ticketId,
                    handlerId: handlerId,
                    statusCode: status.rawValue
                ))
                return try await parser.parseChangeTicketStatus(response)
            },
            
            modifyComment: { id, ticketId, text in
                let response = try await api.send(TicketCommand.Comment.modify(
                    id: id,
                    ticketId: ticketId,
                    text: text
                ))
                let status = Int(response.getResponseStatus())
                return status == 0
            }
        )
    }
    
    // MARK: - Preview Value
    
    public static var previewValue: TicketClient {
        return TicketClient(
            getTicketsList: { _ in
                return .mock
            },
            getTicket: { _ in
                return .mock
            },
            getTicketStatusHistory: { _ in
                return [.mockNotProcessed, .mockProcessing, .mockProcessed]
            },
            changeTicketStatus: { _, _, _ in
                return .success
            },
            modifyComment: { _, _, _ in
                return true
            }
        )
    }
}

// MARK: - Extensions

extension DependencyValues {
    public var ticketClient: TicketClient {
        get { self[TicketClient.self] }
        set { self[TicketClient.self] = newValue }
    }
}

extension String {
    func getResponseStatus() -> String {
        return self
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
            .components(separatedBy: ",")[1]
    }
}
