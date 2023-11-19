//
//  AnalyticsService.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//

import Amplitude

final class AnalyticsService {
    
    typealias EventDictionary = [String: Any]
    
    private let isDebug: Bool
    
    init(isDebug: Bool = false) {
        self.isDebug = isDebug
    }
    
    // MARK: - Public Functions
    
    /// Pass `Event` enum to event parameter
    func event(_ event: String, parameters: EventDictionary? = nil) {
        guard !isDebug else { return }
        Amplitude.instance().logEvent(event, withEventProperties: parameters)
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
