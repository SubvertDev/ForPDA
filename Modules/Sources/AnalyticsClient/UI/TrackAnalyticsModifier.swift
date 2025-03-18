//
//  TrackAnalyticsModifier.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 26.11.2024.
//

import SwiftUI
import PostHog

// MARK: - Modifier

struct TrackAnalyticsModifier: ViewModifier {
    let screenName: String
    let properties: [String: Any]?

    func body(content: Content) -> some View {
        content
            .postHogScreenView(screenName, properties)
    }
}

// MARK: - Modifier Extension

public extension View {
    func trackAnalytics(screenName: String, properties: [String: Any]? = nil) -> some View {
        return modifier(TrackAnalyticsModifier( screenName: screenName, properties: properties))
    }
}
