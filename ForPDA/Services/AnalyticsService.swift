//
//  AnalyticsService.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//
//  swiftlint:disable nesting

import Foundation
import FirebaseAnalytics

final class AnalyticsService {
    
    typealias FADictionary = [String: Any]
    
    // MARK: - Generic Event
    
    private func event(_ name: AnalyticsEvent, parameters: FADictionary?) {
        Analytics.logEvent(name.rawValue, parameters: parameters)
    }
    
    // MARK: - Parameters Cases
    
    private func article(_ url: String) -> FADictionary {
        let url = removeLastComponentAndHttps(url)
        let parameters: FADictionary = [
            AnalyticsParameterKey.Article.url(): url
        ]
        return parameters
    }
    
    private func openLink(currentUrl: String, targetUrl: String) -> FADictionary {
        let currentUrl = removeLastComponentAndHttps(currentUrl)
        let parameters: FADictionary = [
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
}
