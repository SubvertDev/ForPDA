//
//  DeeplinkHandler.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 26.11.2024.
//

import Foundation
import ComposableArchitecture
import AnalyticsClient
import APIClient
import Models

public enum Deeplink {
    case article(id: Int, title: String, imageUrl: URL)
    case announcement(id: Int)
    case topic(id: Int, goTo: GoTo)
    case forum(id: Int)
    case user(id: Int)
}

public struct DeeplinkHandler {
    
    public enum DeeplinkError: Error {
        case noUrlComponents
        case noRegexMatch
        case noMatch
        case badIdOnMatch
        case noComponentsMatch
        case noQueryItems
        case noImageUrl
        case badImageUrl
        case noTitle
        case badTitle
        case unknownType(type: String, for: String)
        case noType(of: String, for: String)
        case noDeeplinkAvailable
    }
    
    @Dependency(\.logger[.deeplink]) private var logger
    @Dependency(\.analyticsClient) private var analytics
    
    public init() {}
    
    // MARK: - Outer To Inner
    
    public func handleOuterToInnerURL(_ url: URL) throws(DeeplinkError) -> Deeplink {
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

            return .article(id: id, title: title, imageUrl: imageUrl)
            
        default:
            throw .noComponentsMatch
        }
    }
    
    // MARK: - Inner To Inner
    
    public func handleInnerToInnerURL(_ url: URL) throws(DeeplinkError) -> Deeplink {
        if url.scheme == "snapback", let postIdString = url.host(), let postId = Int(postIdString) {
            let topicIdString = url.path()
            if let topicId = Int(String(topicIdString.dropFirst())) {
                return .topic(id: topicId, goTo: .post(id: postId))
            }
        }
        
        guard let host = url.host, host == "4pda.to" else { throw .noDeeplinkAvailable }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw .noUrlComponents }
        
        guard let queryItems = components.queryItems else { throw .noQueryItems }
        
        // showtopic
        
        if let topicItem = queryItems.first(where: { $0.name == "showtopic" }), let value = topicItem.value, let topicId = Int(value) {
            if let viewType = queryItems.first(where: { $0.name == "view" })?.value {
                switch viewType {
                case "findpost":
                    if let postItem = queryItems.first(where: { $0.name == "p" }), let value = postItem.value, let postId = Int(value) {
                        // https://4pda.to/forum/index.php?showtopic=123456&view=findpost&p=123456789
                        return .topic(id: topicId, goTo: .post(id: postId))
                    } else {
                        analytics.capture(DeeplinkError.noType(of: "p", for: "showtopic"))
                    }
                    
                case "getnewpost":
                    // https://4pda.to/forum/index.php?showtopic=123456&view=getnewpost
                    return .topic(id: topicId, goTo: .last)
                    
                default:
                    analytics.capture(DeeplinkError.unknownType(type: viewType, for: url.absoluteString))
                }
            }
            
            // https://4pda.to/forum/index.php?showtopic=123456
            return .topic(id: topicId, goTo: .first)
        }
        
        // showforum
        
        if let forumItem = queryItems.first(where: { $0.name == "showforum" }), let value = forumItem.value, let forumId = Int(value) {
            // https://4pda.to/forum/index.php?showforum=123
            return .forum(id: forumId)
        }
        
        if let announcementItem = queryItems.first(where: { $0.name == "act" }), let actType = announcementItem.value {
            switch actType {
            case "announce":
                analytics.capture(DeeplinkError.noType(of: "announce", for: url.absoluteString))
                #warning("not-tested")
                // if let announceItem = queryItems.first(where: { $0.name == "p" }), let value = announceItem.value, let announceId = Int(value) {
                //     return .announcement(id: announceId)
                // } else {
                //     analytics.capture(DeeplinkError.noType(of: "p", for: "showannouncement"))
                // }
                
            case "boardrules":
                // https://4pda.to/forum/index.php?act=boardrules
                return .announcement(id: 0)
                
            default:
                analytics.capture(DeeplinkError.unknownType(type: actType, for: url.absoluteString))
            }
        }
        
        // showuser
        
        if let userItem = queryItems.first(where: { $0.name == "showuser" }), let value = userItem.value, let userId = Int(value) {
            // https://4pda.to/forum/index.php?showuser=1234567
            return .user(id: userId)
        }
        
        throw .noDeeplinkAvailable
    }
    
    // MARK: - Inner To Outer
    
    public func handleInnerToOuterURL(_ url: URL) async -> URL {
        let id = Int(url.absoluteString.replacingOccurrences(of: "link://", with: ""))!
        @Dependency(\.apiClient) var apiClient
        let url = try! await apiClient.getAttachment(id)
        return url
    }
}
