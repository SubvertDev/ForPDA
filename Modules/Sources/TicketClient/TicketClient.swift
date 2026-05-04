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
                    sortType: data.sort.rawValue,
                    offset: data.offset,
                    limit: data.amount
                ))
                return try await parser.parseTicketsList(response)
            }
        )
    }
    
    // MARK: - Preview Value
    
    public static var previewValue: TicketClient {
        return TicketClient(
            getTicketsList: { _ in
                return .mock
            }
        )
    }
}

extension DependencyValues {
    public var ticketClient: TicketClient {
        get { self[TicketClient.self] }
        set { self[TicketClient.self] = newValue }
    }
}
