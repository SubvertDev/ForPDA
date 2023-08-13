//
//  AnalyticsService.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//
//  swiftlint:disable nesting

import Foundation
import AmplitudeSwift

final class AnalyticsService {
    
    typealias EventDictionary = [String: String]
    
    private let amplitude = Amplitude(configuration: Configuration(
        apiKey: Secrets.amplitude,
        logLevel: .WARN,
        serverZone: .EU
    ))
    
    let isDebug: Bool
    
    init(isDebug: Bool = false) {
        self.isDebug = isDebug
        amplitude.configuration.optOut = isDebug
    }
    
    // MARK: - Generic Event
    
    private func event(_ name: AnalyticsEvent, parameters: EventDictionary?) {
        guard !isDebug else { return }
        let event = BaseEvent(
            eventType: name.rawValue,
            eventProperties: parameters
        )
        
        amplitude.track(event: event)
    }
    
    // MARK: - Parameters Cases
    
    private func article(_ url: String) -> EventDictionary {
        let url = removeLastComponentAndHttps(url)
        let parameters: EventDictionary = [
            AnalyticsParameterKey.Article.url(): url
        ]
        return parameters
    }
    
    private func openLink(currentUrl: String, targetUrl: String) -> EventDictionary {
        let currentUrl = removeLastComponentAndHttps(currentUrl)
        let parameters: EventDictionary = [
            AnalyticsParameterKey.Article.url(): currentUrl,
            AnalyticsParameterKey.Article.linkTo(): targetUrl
        ]
        return parameters
    }
    
}

// MARK: - Enums

extension AnalyticsService {
    
    enum AnalyticsEvent: String {
        // News
        case openArticle
        
        // News & Article
        case copyArticleLink
        case shareArticleLink
        case reportBrokenArticle
        
        // Article
        case clickLinkInArticle
        case clickButtonInArticle
    }

    enum AnalyticsParameterKey {
        enum Article: String {
            case id
            case url
            case title
            case linkTo
            
            func callAsFunction() -> String {
                return self.rawValue.toSnakeCase()
            }
        }
    }
}

// MARK: - Events

extension AnalyticsService {
    func openArticleEvent(_ url: String) {
        event(.openArticle, parameters: article(url))
    }
    
    func copyArticleLink(_ url: String) {
        event(.copyArticleLink, parameters: article(url))
    }
    
    func shareArticleLink(_ url: String) {
        event(.shareArticleLink, parameters: article(url))
    }
    
    func reportBrokenArticle(_ url: String) {
        event(.reportBrokenArticle, parameters: article(url))
        reportArticle(url)
    }
    
    func clickLinkInArticle(currentUrl: String, targetUrl: String) {
        event(.clickLinkInArticle, parameters: openLink(currentUrl: currentUrl, targetUrl: targetUrl))
    }
    
    func clickButtonInArticle(currentUrl: String, targetUrl: String) {
        event(.clickButtonInArticle, parameters: openLink(currentUrl: currentUrl, targetUrl: targetUrl))
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
        guard let url = URL(string: "https://api.telegram.org/bot\(Secrets.telegramToken)/sendMessage") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        var user: User?
        if let userData = UserDefaults.standard.data(forKey: "userId") {
            user = try? JSONDecoder().decode(User.self, from: userData)
        }
        
        let jsonBody = """
        {
            "chat_id": \(Secrets.telegramChatID),
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
