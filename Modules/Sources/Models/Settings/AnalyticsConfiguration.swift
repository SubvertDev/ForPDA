//
//  AnalyticsConfiguration.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.11.2024.
//

import Foundation

public struct AnalyticsConfiguration: Sendable, Codable, Hashable {
    public var isAnalyticsEnabled: Bool
    public var isAnalyticsDebugEnabled: Bool
    public var isCrashlyticsEnabled: Bool
    public var isCrashlyticsDebugEnabled: Bool
    
    public init(
        isAnalyticsEnabled: Bool,
        isAnalyticsDebugEnabled: Bool,
        isCrashlyticsEnabled: Bool,
        isCrashlyticsDebugEnabled: Bool
    ) {
        self.isAnalyticsEnabled = isAnalyticsEnabled
        self.isAnalyticsDebugEnabled = isAnalyticsDebugEnabled
        self.isCrashlyticsEnabled = isCrashlyticsEnabled
        self.isCrashlyticsDebugEnabled = isCrashlyticsDebugEnabled
    }
}

public extension AnalyticsConfiguration {
    static let debug = AnalyticsConfiguration(
        isAnalyticsEnabled: false,
        isAnalyticsDebugEnabled: false,
        isCrashlyticsEnabled: false,
        isCrashlyticsDebugEnabled: true
    )
    
    static let release = AnalyticsConfiguration(
        isAnalyticsEnabled: true,
        isAnalyticsDebugEnabled: false,
        isCrashlyticsEnabled: true,
        isCrashlyticsDebugEnabled: false
    )
}
