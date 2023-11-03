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
        var url = URL(string: url) ?? URL(string: "https://4pda.to/")!
        if url.pathComponents.count == 6 { url.deleteLastPathComponent() }
        var urlString = url.absoluteString
        urlString = urlString.replacingOccurrences(of: "https://", with: "")
        return urlString
    }
    
    func reportArticle(_ reportUrl: String) {
        guard let url = URL(string: "https://api.telegram.org/bot\(Secrets.for(key: .TELEGRAM_TOKEN))/sendMessage") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        var user: User?
        if let userData = UserDefaults.standard.data(forKey: "userId") {
            user = try? JSONDecoder().decode(User.self, from: userData)
        }
        
        let jsonBody = """
        {
            "chat_id": \(Secrets.for(key: .TELEGRAM_CHAT_ID)),
            "text": "[\(user?.id ?? "-"):\(user?.nickname ?? "-")]\n\(reportUrl)"
        }
        """
        request.httpBody = jsonBody.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if error != nil { return }
            guard let response = (response as? HTTPURLResponse)?.statusCode, response == 200 else {
                print("Error sending report for \(reportUrl)")
                return
            }
            print("Report succesfully sent (\(reportUrl)")
        }.resume()
    }
    
}
