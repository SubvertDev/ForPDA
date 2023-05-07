//
//  AnalyticsHelper.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//
//  swiftlint:disable nesting

import Foundation
import FirebaseAnalytics

final class AnalyticsHelper {
    
    typealias FADictionary = [String: Any]
    
    // MARK: - Generic Event
    
    private static func event(_ name: AnalyticsEvent, parameters: FADictionary?) {
        Analytics.logEvent(name.rawValue, parameters: parameters)
    }
    
    // MARK: - Parameters Cases
    
    private static func article(_ url: String) -> FADictionary {
        var url = removeLastComponentAndHttps(url)
        let parameters: FADictionary = [
            AnalyticsParameterKey.Article.url(): url
        ]
        return parameters
    }
    
    private static func openLink(currentUrl: String, targetUrl: String) -> FADictionary {
        var currentUrl = removeLastComponentAndHttps(currentUrl)
        let parameters: FADictionary = [
            AnalyticsParameterKey.Article.url(): currentUrl,
            AnalyticsParameterKey.Article.linkTo(): targetUrl
        ]
        return parameters
    }
    
}

// MARK: - Enums

extension AnalyticsHelper {
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

extension AnalyticsHelper {
    static func openArticleEvent(_ url: String) {
        event(.openArticle, parameters: article(url))
    }
    
    static func copyArticleLink(_ url: String) {
        event(.copyArticleLink, parameters: article(url))
    }
    
    static func shareArticleLink(_ url: String) {
        event(.shareArticleLink, parameters: article(url))
    }
    
    static func reportBrokenArticle(_ url: String) {
        event(.reportBrokenArticle, parameters: article(url))
    }
    
    static func clickLinkInArticle(currentUrl: String, targetUrl: String) {
        event(.clickLinkInArticle, parameters: openLink(currentUrl: currentUrl, targetUrl: targetUrl))
    }
    
    static func clickButtonInArticle(currentUrl: String, targetUrl: String) {
        event(.clickButtonInArticle, parameters: openLink(currentUrl: currentUrl, targetUrl: targetUrl))
    }
}

// MARK: - Helper Functions

extension AnalyticsHelper {
    private static func removeLastComponentAndHttps(_ url: String) -> String {
        var url = URL(string: url) ?? URL(string: "https://4pda.to/")!
        if url.pathComponents.count == 6 { url.deleteLastPathComponent() }
        var urlString = url.absoluteString
        urlString = urlString.replacingOccurrences(of: "https://", with: "")
        return urlString
    }
}
