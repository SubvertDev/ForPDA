//
//  NotificationsDeliveryMethod.swift
//  ForPDA
//
//  Created by subvert on 23/10/2026.
//

public enum NotificationsDeliveryMethod: CaseIterable, Identifiable, Codable, Sendable {
    
    case push
    case background
    
    public var id: String {
        description
    }
    
    var description: String {
        switch self {
        case .push:
            return "Push"
        case .background:
            return "Background"
        }
    }
}
