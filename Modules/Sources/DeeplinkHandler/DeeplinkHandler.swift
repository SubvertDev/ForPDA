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
    case topic(id: Int?, goTo: GoTo)
    case forum(id: Int, page: Int)
    case user(id: Int)
}

public struct DeeplinkHandler {
    
    public enum DeeplinkError: Error {
        case noUrlComponents(in: URL)
        case noRegexMatch(in: URL)
        case noMatch(in: URL)
        case badIdOnMatch(in: URL)
        case noComponentsMatch(in: URL)
        case noQueryItems(in: URL)
        case noImageUrl(in: URL)
        case badImageUrl(in: URL)
        case noTitle(in: URL)
        case badTitle(in: URL)
        case unknownType(type: String, for: String)
        case noType(of: String, for: String)
        case noDeeplinkAvailable(for: URL)
        case externalURL
    }
    
    @Dependency(\.logger[.deeplink]) private var logger
    @Dependency(\.analyticsClient) private var analytics
    
    public init() {}
    
    // MARK: - Outer To Inner
    
    public func handleOuterToInnerURL(_ url: URL) throws(DeeplinkError) -> Deeplink {
        logger.info("Handling outer deeplink URL: \(url.absoluteString.removingPercentEncoding ?? "encoding error")")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { throw .noUrlComponents(in: url) }
        
        switch components.host {
        case "article":
            // ID
            let regex = #//([\d]{6})//#
            guard let match = url.absoluteString.firstMatch(of: regex) else { throw .noRegexMatch(in: url) }
            guard let id = Int(match.output.1) else { throw .badIdOnMatch(in: url) }
            
            guard let queryItems = components.queryItems else { throw .noQueryItems(in: url) }
            
            // Image URL
            guard let imageUrlString = queryItems.first(where: { $0.name == "imageUrl"} )?.value else { throw .noImageUrl(in: url) }
            guard let imageUrl = URL(string: imageUrlString) else { throw .badImageUrl(in: url) }
            
            // Title
            guard let titleEncoded = queryItems.first(where: { $0.name == "title"} )?.value else { throw .noTitle(in: url) }
            guard let title = titleEncoded.removingPercentEncoding else { throw .badTitle(in: url) }

            return .article(id: id, title: title, imageUrl: imageUrl)
            
        case "forum":
            guard let id = Int(url.lastPathComponent) else { throw .badIdOnMatch(in: url) }
            if let offset = components.queryItems?.first?.value.flatMap({Int($0)}) {
                @Shared(.appSettings) var appSettings: AppSettings
                let page = getPage(forOffset: offset, userPerPage: appSettings.forumPerPage)
                return .forum(id: id, page: page)
            } else {
                return .forum(id: id, page: 1)
            }
            
        case "announce":
            guard let _ = Int(url.lastPathComponent) else { throw .badIdOnMatch(in: url) } // forumId
            guard let announceId = components.queryItems?.first?.value.flatMap({Int($0)}) else { throw .badIdOnMatch(in: url) }
            return .announcement(id: announceId)
            
        case "topic":
            guard let id = Int(url.lastPathComponent) else { throw .badIdOnMatch(in: url) }
            if let offset = components.queryItems?.first?.value.flatMap({Int($0)}) {
                @Shared(.appSettings) var appSettings: AppSettings
                let page = getPage(forOffset: offset, userPerPage: appSettings.topicPerPage)
                return .topic(id: id, goTo: .page(page))
            } else {
                return .topic(id: id, goTo: .first)
            }
            
        case "user":
            guard let id = Int(url.lastPathComponent) else { throw .badIdOnMatch(in: url) }
            return .user(id: id)
            
        default:
            throw .noComponentsMatch(in: url)
        }
    }
    
    private func getPage(forOffset offset: Int, userPerPage: Int) -> Int {
        return Int(ceil(Double(offset + 1) / Double(userPerPage)))
    }
    
    // MARK: - Inner To Inner
    
    public func handleInnerToInnerURL(_ url: URL) throws(DeeplinkError) -> Deeplink {
        if url.scheme == "snapback", let postIdString = url.host(), let postId = Int(postIdString) {
            let topicIdString = url.path()
            if let topicId = Int(String(topicIdString.dropFirst())) {
                return .topic(id: topicId, goTo: .post(id: postId))
            }
        }
        
        guard let host = url.host, host == "4pda.to" else { throw .externalURL }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { throw .noUrlComponents(in: url) }
        
        guard let queryItems = components.queryItems else { throw .noQueryItems(in: url) }
        
        // showtopic
        
        if let topicItem = queryItems.first(where: { $0.name == "showtopic" }), let value = topicItem.value, let topicId = Int(value) {
            if let viewType = queryItems.first(where: { $0.name == "view" })?.value {
                switch viewType {
                case "findpost":
                    if let postItem = queryItems.first(where: { $0.name == "p" }), let value = postItem.value, let postId = Int(value) {
                        // https://4pda.to/forum/index.php?showtopic=123456&view=findpost&p=123456789
                        return .topic(id: topicId, goTo: .post(id: postId))
                    } else {
                        analytics.capture(DeeplinkError.noType(of: "p", for: url.absoluteString))
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
            // https://4pda.to/forum/index.php?showtopic=1104159
            return .forum(id: forumId, page: 1)
        }
        
        if let announcementItem = queryItems.first(where: { $0.name == "act" }), let actType = announcementItem.value {
            switch actType {
            case "announce":
                // https://4pda.to/forum/index.php?act=announce&f=140&st=238
                 if let announceItem = queryItems.first(where: { $0.name == "st" }), let value = announceItem.value, let announceId = Int(value) {
                     return .announcement(id: announceId)
                 } else {
                     analytics.capture(DeeplinkError.noType(of: "st", for: url.absoluteString))
                 }
                
            case "boardrules":
                // https://4pda.to/forum/index.php?act=boardrules
                return .announcement(id: 0)
                
            case "findpost":
                // https://4pda.to/forum/index.php?act=findpost&pid=136063497
                if let postItem = queryItems.first(where: { $0.name == "pid" }), let value = postItem.value, let postId = Int(value) {
                    return .topic(id: nil, goTo: .post(id: postId))
                } else {
                    analytics.capture(DeeplinkError.noType(of: "pid", for: url.absoluteString))
                }
                
            default:
                analytics.capture(DeeplinkError.unknownType(type: actType, for: url.absoluteString))
            }
        }
        
        // showuser
        
        if let userItem = queryItems.first(where: { $0.name == "showuser" }), let value = userItem.value, let userId = Int(value) {
            // https://4pda.to/forum/index.php?showuser=1234567
            return .user(id: userId)
        }
        
        throw .noDeeplinkAvailable(for: url)
    }
    
    // MARK: - Inner To Outer
    
    public func handleInnerToOuterURL(_ url: URL) async -> URL {
        let id = Int(url.absoluteString.replacingOccurrences(of: "link://", with: ""))!
        @Dependency(\.apiClient) var apiClient
        let url = try! await apiClient.getAttachment(id)
        return url
    }
    
    // MARK: - Notification
    
    public func handleNotification(_ identifier: String) throws(DeeplinkError) -> Deeplink {
        let split = identifier.split(separator: "-")
        let url = URL(string: "notification://\(identifier)")!
        
        guard let typeString = split.first,     let typeInt = Int(typeString)        else { throw .noDeeplinkAvailable(for: url) }
        guard let idString = split[safe: 1],    let id = Int(idString)               else { throw .noDeeplinkAvailable(for: url) }
        guard let timestampString = split.last, let timestamp = Int(timestampString) else { throw .noDeeplinkAvailable(for: url) }
        
        guard let type = Unread.Item.Category(rawValue: typeInt) else { throw .noDeeplinkAvailable(for: url) }
        
        switch type {
        case .qms:
            // TODO: Add
            break
        case .forum:
            return Deeplink.forum(id: id, page: 1)
        case .topic:
            // Currently we don't have id of a post to jump due to limited api
            return Deeplink.topic(id: id, goTo: .unread)
        case .forumMention:
            // Forum mention has topic id in timestamp place
            return Deeplink.topic(id: timestamp, goTo: .post(id: id))
        case .siteMention:
            return Deeplink.article(id: id, title: "", imageUrl: URL(string: "/")!)
        }
        
        throw .noDeeplinkAvailable(for: url)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
