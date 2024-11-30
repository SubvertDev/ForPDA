//
//  DeeplinkHandler.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 26.11.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient

public struct Deeplink {
    public let tab: Tab
    
    public enum Tab {
        case articles(Articles)
        case forum(Forum)
        case profile(Int)
        
        public enum Articles {
            case article(id: Int, title: String, imageUrl: URL)
        }
        
        public enum Forum {
            case forum(id: Int)
            case topic(id: Int)
        }
    }
}

public struct DeeplinkHandler {
    
    public enum DeeplinkError: Error {
        case noUrlComponents
        case noRegexMatch
        case badIdOnMatch
        case noComponentsMatch
        case noQueryItems
        case noImageUrl
        case badImageUrl
        case noTitle
        case badTitle
    }
    
    @Dependency(\.logger[.deeplink]) private var logger
    @Dependency(\.analyticsClient) private var analytics
    
    public init() {}
    
    public func handleOuterURL(_ url: URL) throws(DeeplinkError) -> Deeplink {
        logger.info("Handling outer deeplink URL: \(url.absoluteString.removingPercentEncoding ?? "encoding error")")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw .noUrlComponents }
        
        switch components.host {
        case "article":
            // ID
            let regex = #//([\d]{6})//#
            guard let match = url.absoluteString.firstMatch(of: regex) else { throw .noRegexMatch }
            guard let id = Int(match.output.1) else { throw .badIdOnMatch }
            
            guard let queryItems = components.queryItems else { throw .noQueryItems }
            
            // Image URL
            guard let imageUrlString = queryItems.first(where: { $0.name == "imageUrl"} )?.value else { throw .noImageUrl }
            guard let imageUrl = URL(string: imageUrlString) else { throw .badImageUrl }
            
            // Title
            guard let titleEncoded = queryItems.first(where: { $0.name == "title"} )?.value else { throw .noTitle }
            guard let title = titleEncoded.removingPercentEncoding else { throw .badTitle }

            return Deeplink(tab: .articles(.article(id: id, title: title, imageUrl: imageUrl)))
            
        default:
            throw .noComponentsMatch
        }
    }
    
    public func handleInnerURL(_ url: URL) throws(DeeplinkError) -> Deeplink? {
        let regex = /=(\d+)/
        
        guard let match = url.absoluteString.firstMatch(of: regex) else { throw .noRegexMatch }
        guard let id = Int(match.output.1) else { throw .badIdOnMatch }
        
        switch DeeplinkUrlType.unwrap(from: url) {
        case .topic:
            return Deeplink(tab: .forum(.topic(id: id)))
        case .forum:
            return Deeplink(tab: .forum(.forum(id: id)))
        case .profile:
            return Deeplink(tab: .profile(id))
        case .unknown:
            return nil
        }
    }
    
    enum DeeplinkUrlType: String, CaseIterable {
        case topic = "showtopic"
        case forum = "showforum"
        case profile = "showuser"
        case unknown
        
        static func unwrap(from url: URL) -> DeeplinkUrlType {
            for type in DeeplinkUrlType.allCases {
                if url.absoluteString.contains(type.rawValue) {
                    return type
                }
            }
            return .unknown
        }
    }
}
