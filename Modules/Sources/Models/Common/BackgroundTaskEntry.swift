//
//  BackgroundTaskEntry.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 24.02.2026.
//

import Foundation

public struct BackgroundTaskEntry: Hashable, Codable, Sendable {
    
    public enum Stage: Hashable, Codable, Sendable {
        case invoked
        case startedSync
        case startedAsync
        case checkingForPermission
        case checkingForSettings
        case connecting
        case gettingNotifications
        case showingNotifications
        case success
        case failure(String)
        case finished
        
        case registrationBegin
        case registrationSuccess
        case registrationFailed(String)
    }
    
    public let date: Date
    public let stage: Stage
    
    public init(stage: Stage) {
        self.date = .now
        self.stage = stage
    }
}
