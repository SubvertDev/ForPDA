//
//  TrackingModifier.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 18.03.2025.
//

import SwiftUI

// MARK: - Modifier

struct TrackingModifier<V: View>: ViewModifier {
    
    let viewName: String
    let properties: [String: Any]?
    
    init(
        for type: V.Type,
        waitForFullDisplay: Bool? = nil,
        properties: [String : Any]? = nil
    ) {
        self.viewName = Self.getScreenName(from: type)
        self.properties = properties
    }

    func body(content: Content) -> some View {
        content
            .tracePerformance(viewName: viewName)
            .trackAnalytics(screenName: viewName, properties: properties)
    }
    
    private static func getScreenName(from type: V.Type) -> String {
        var result = ""
        for char in String(describing: type) {
            if char.isUppercase && !result.isEmpty {
                result.append(" ")
            }
            result.append(char)
        }
        return result
    }
}

// MARK: - Modifier Extension

public extension View {
    /// Adds analytics & performance tracking to the view
    /// - Parameters:
    ///   - type: type of screen that it's being used on (necessary for name extraction)
    ///   - properties: analytics sent to PostHog, default is nil
    func tracking<V: View>(
        for type: V.Type,
        _ properties: [String: Any]? = nil
    ) -> some View {
        return modifier(
            TrackingModifier(
                for: type,
                properties: properties
            )
        )
    }
}
