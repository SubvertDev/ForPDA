//
//  TracePerformanceView+Modifier.swift
//  AnalyticsClient
//
//  Created by Ilia Lubianoi on 18.03.2025.
//

import SwiftUI
import SentrySwiftUI

// MARK: - View

public struct TracePerformanceView<Content: View>: View {
    
    let viewName: String?
    let content: Content
    
    public init(
        _ viewName: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.viewName = viewName
        self.content = content()
    }
    
    public var body: some View {
        SentryTracedView(viewName) {
            content
        }
    }
}

// MARK: - Modifier

struct TracePerformanceModifier: ViewModifier {
    
    let viewName: String

    func body(content: Content) -> some View {
        content
            .sentryTrace(viewName)
    }
}

// MARK: - Modifier Extension

public extension View {
    func tracePerformance(viewName: String) -> some View {
        return modifier(TracePerformanceModifier(viewName: viewName))
    }
}
