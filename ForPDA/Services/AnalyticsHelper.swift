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
    
    private static func analyticsArticle(_ articleEvent: ArticleEvent) -> [String: Any] {
        let parameters: [String: Any] = [
            AnalyticsParameterKey.Article.link.name: articleEvent.link
        ]
        return parameters
    }
    
    private static func analyticsOpenLink(_ articleEvent: ArticleEvent) -> [String: Any] {
        let parameters: [String: Any] = [
            AnalyticsParameterKey.Article.link.name: articleEvent.link,
            AnalyticsParameterKey.Article.linkTo.name: articleEvent.linkTo ?? "BAD LINK"
        ]
        return parameters
    }
}

struct ArticleEvent {
    let link: String
    let linkTo: String?
    
    init(link: String, linkTo: String? = nil) {
        self.link = link
        self.linkTo = linkTo
    }
}

extension AnalyticsHelper {
    static func openArticleEvent(_ articleEvent: ArticleEvent) {
        event(with: .openArticle, parameters: analyticsArticle(articleEvent))
    }
    
    static func copyArticleLink(_ articleEvent: ArticleEvent) {
        event(with: .copyArticleLink, parameters: analyticsArticle(articleEvent))
    }
    
    static func shareArticleLink(_ articleEvent: ArticleEvent) {
        event(with: .shareArticleLink, parameters: analyticsArticle(articleEvent))
    }
    
    static func clickLinkInArticle(_ articleEvent: ArticleEvent) {
        event(with: .clickLinkInArticle, parameters: analyticsOpenLink(articleEvent))
    }
    
    static func clickButtonInArticle(_ articleEvent: ArticleEvent) {
        event(with: .clickButtonInArticle, parameters: analyticsOpenLink(articleEvent))
    }
}

enum AnalyticsEvent {
    case openArticle
    case copyArticleLink
    case shareArticleLink
    case clickLinkInArticle
    case clickButtonInArticle
    
    var name: String {
        switch self {
        case .openArticle:
            return AnalyticsEventSelectItem

        case .shareArticleLink:
            return AnalyticsEventShare
            
        case .copyArticleLink,
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
                return AnalyticsParameterSource
            }
        }
    }
}
