//
//  TicketStatus.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

import Foundation

public enum TicketStatus: Int, Sendable, CaseIterable, Identifiable {
    case notProcessed = 0
    case processing   = 1
    case processed    = 2
    
    public var id: Int {
        return self.rawValue
    }
    
    public var title: LocalizedStringResource {
        switch self {
        case .notProcessed:
            return .init("Not processed", bundle: .module)
        case .processing:
            return .init("Processing", bundle: .module)
        case .processed:
            return .init("Processed", bundle: .module)
        }
    }
}
