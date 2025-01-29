//
//  File.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 26.11.2024.
//

import SwiftUI
import PostHog

struct AnalyticsModifier: ViewModifier {
    let viewEventName: String
    let screenEvent: Bool
    let properties: [String: Any]?

    func body(content: Content) -> some View {
        content.onAppear {
            if screenEvent {
                PostHogSDK.shared.screen(viewEventName, properties: properties)
            } else {
                PostHogSDK.shared.capture(viewEventName, properties: properties)
            }
        }
    }
}

public extension View {
    func trackAnalytics(
        _ screenName: String? = nil,
        isScreen: Bool = true,
        _ properties: [String: Any]? = nil
    ) -> some View {
        let viewEventName = screenName ?? "\(type(of: self))"
        return modifier(AnalyticsModifier(
            viewEventName: viewEventName,
            screenEvent: isScreen,
            properties: properties)
        )
    }
}
