//
//  TicketStatus.swift
//  ForPDA
//
//  Created by Xialtal on 3.05.26.
//

import SwiftUI

public enum TicketStatus: Int, Sendable, CaseIterable, Identifiable {
    case notProcessed = 0
    case processing   = 1
    case processed    = 2
    
    public var id: Int {
        return self.rawValue
    }
    
    public var title: LocalizedStringKey {
        switch self {
        case .notProcessed:
            return "Not processed"
        case .processing:
            return "Processing"
        case .processed:
            return "Processed"
        }
    }
}
