//
//  TicketStatusChangeResponse.swift
//  ForPDA
//
//  Created by Xialtal on 8.05.26.
//

public enum TicketStatusChangeResponse: Sendable {
    case success
    case failure(TicketStatusChangeError)
    
    public enum TicketStatusChangeError: Sendable {
        case handlerChanged(id: Int, name: String)
        case other
    }
}
