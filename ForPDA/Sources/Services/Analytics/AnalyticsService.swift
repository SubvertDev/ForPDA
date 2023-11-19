//
//  AnalyticsService.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//

import Foundation
import Mixpanel

final class AnalyticsService {
    
    /// Pass `Event` enum to event parameter
    func event(_ event: String, parameters: Properties? = nil) {
        guard !AppScheme.isDebug else { return }
        Mixpanel.mainInstance().track(event: event, properties: parameters)
    }
}

// MARK: - Helper Functions

extension AnalyticsService {
    
    private func removeLastComponentAndHttps(_ url: String) -> String {
        var url = URL(string: url) ?? URL.fourpda
        if url.pathComponents.count == 6 { url.deleteLastPathComponent() }
        var urlString = url.absoluteString
        urlString = urlString.replacingOccurrences(of: "https://", with: "")
        return urlString
    }
}
