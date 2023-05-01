//
//  AnalyticsHelper.swift
//  ForPDA
//
//  Created by Subvert on 01.05.2023.
//

import Foundation
import FirebaseAnalytics

final class AnalyticsHelper {
    private static func event(with type: AnalyticsEvent, parameters: [String: Any]? = nil) {
        Analytics.logEvent(type.name, parameters: parameters)
    }
    
    private static func analyticsArticle(_ url: String) -> [String: Any] {
        let url = removeLastComponentAndHttps(url)
        let parameters: [String: Any] = [
            AnalyticsParameterKey.Article.link.name: url
        ]
        return parameters
    }
    
    private static func analyticsOpenLink(currentUrl: String, targetUrl: String) -> [String: Any] {
        let currentUrl = removeLastComponentAndHttps(currentUrl)
        let parameters: [String: Any] = [
            AnalyticsParameterKey.Article.link.name: currentUrl,
            AnalyticsParameterKey.Article.linkTo.name: targetUrl
        ]
        return parameters
    }
    
    private static func removeLastComponentAndHttps(_ url: String) -> String {
        var url = URL(string: url) ?? URL(string: "https://4pda.to/")!
        if url.pathComponents.count == 6 { url.deleteLastPathComponent() }
        var urlString = url.absoluteString
        urlString = urlString.replacingOccurrences(of: "https://", with: "")
        return urlString
    }
}

extension AnalyticsHelper {
    static func openArticleEvent(_ url: String) {
        event(with: .openArticle, parameters: analyticsArticle(url))
    }
    
    static func copyArticleLink(_ url: String) {
        event(with: .copyArticleLink, parameters: analyticsArticle(url))
    }
    
    static func shareArticleLink(_ url: String) {
        event(with: .shareArticleLink, parameters: analyticsArticle(url))
    }
    
    static func reportBrokenArticle(_ url: String) {
        event(with: .reportBrokenArticle, parameters: analyticsArticle(url))
    }
    
    static func clickLinkInArticle(currentUrl: String, targetUrl: String) { //
        event(with: .clickLinkInArticle, parameters: analyticsOpenLink(currentUrl: currentUrl, targetUrl: targetUrl))
    }
    
    static func clickButtonInArticle(currentUrl: String, targetUrl: String) { //
        event(with: .clickButtonInArticle, parameters: analyticsOpenLink(currentUrl: currentUrl, targetUrl: targetUrl))
    }
}

enum AnalyticsEvent {
    case openArticle
    
    case copyArticleLink
    case shareArticleLink
    case reportBrokenArticle
    
    case clickLinkInArticle
    case clickButtonInArticle
    
    var name: String {
        switch self {
        case .openArticle:
            return AnalyticsEventSelectItem

        case .shareArticleLink:
            return AnalyticsEventShare
            
        case .copyArticleLink,
             .reportBrokenArticle,
             .clickLinkInArticle,
             .clickButtonInArticle:
            return String(describing: self)
        }
    }
}
 
enum AnalyticsParameterKey {
    enum Article {
        case id
        case link
        case title
        case linkTo
        
        var name: String {
            switch self {
            case .id:
                return AnalyticsParameterItemID
            case .link:
                return AnalyticsParameterSource
            case .title:
                return AnalyticsParameterItemName
            case .linkTo:
                return "link_to"
            }
        }
    }
}
