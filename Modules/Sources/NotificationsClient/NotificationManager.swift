//
//  NotificationManager.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 12.08.2026.
//

import CacheClient
import ComposableArchitecture
import Models
import UserNotifications

public final class NotificationManager: @unchecked Sendable {
    
    // MARK: - Types
    
    public enum PushDecision {
        case deliver(title: String, body: String)
        case suppress
    }
    
    public enum NotificationClearType {
        case kind(PDANotification.Kind)
        case primaryId(Int)
        case value(Int)
    }
    
    // MARK: - Properties
    
    private let center = UNUserNotificationCenter.current()
    
    @Shared(.appSettings) var appSettings

    @Dependency(\.analyticsClient) var analytics
    @Dependency(\.logger[.notifications]) var logger
    
    // MARK: - Init
    
    public init() {}
    
    // MARK: - Public
    
    public func handlePushNotification(item: PDANotification) async -> PushDecision {
        do {
            let notification = try item.toDomain()
            
            guard processNotification(item: notification, context: nil) else {
                return .suppress
            }
            
            await clearNotifications(item: item)
            
            let content = buildNotificationContent(item: notification)
            return .deliver(title: content.title, body: content.body)
        } catch {
            analytics.capture(error)
            logger.error("Invalid notification payload: \(String(describing: error))")
            return .suppress
        }
    }
    
    public func handleLocalNotifications(items: [PDANotification], context: NotificationContext?) async {
        for item in items {
            do {
                let notification = try item.toDomain()

                guard processNotification(item: notification, context: context) else {
                    continue
                }

                await clearNotifications(item: item)

                await showLocalNotification(
                    identifier: item.identifier.rawValue,
                    content: buildNotificationContent(item: notification)
                )
            } catch {
                analytics.capture(error)
                logger.error("Skipping invalid notification: \(String(describing: error))")
            }
        }
    }
    
    public func clear(by type: NotificationClearType) async {
        let notifications = await center.deliveredNotifications()
        
        let identifiers = notifications
            .filter { notification in
                guard let identifier = notification.request.pdaIdentifier else { return false }
                switch type {
                case let .kind(kind):
                    return identifier.kind == kind
                case let .primaryId(id):
                    return identifier.primaryID == id
                case let .value(value):
                    return identifier.value == value
                }
            }
            .map(\.request.identifier)
        
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    // MARK: - Process
    
    func processContext(item: PDANotificationDomain, context: NotificationContext?) -> Bool {
        switch (context, item) {
            
            // Do not show notification of a message of a chat that we're currently in
        case let (.chat(id), .qmsMessage(qms)) where id == qms.threadID:
            logger.info("Skipping notification in QMS context. Thread ID: \(qms.threadID)")
            return false
            
        case (.favorites, .newTopic), (.favorites, .newPost):
            logger.info("Skipping notification in favorites context. Topic/Post ID: \(item.toRaw().primaryID)")
            return false
            
        case (.mentions, .forumMention), (.mentions, .siteMention):
            logger.info("Skipping notification in mentions context. Post/Comment ID: \(item.toRaw().primaryID)")
            return false
            
        case let (.topic(id), .newPost(post)) where id == post.topicID:
            logger.info("Skipping notification in topic context. Post ID: \(item.toRaw().primaryID)")
            return false

        default:
            return true
        }
    }
    
    func processNotification(item: PDANotificationDomain, context: NotificationContext?) -> Bool {
        @Shared(.notificationsCache) var notificationsCache
        
        switch item {
        case let .qmsMessage(model):
            // Check for last message id of qms thread
            if notificationsCache.qms[model.threadID] == model.messageID {
                // Same message id -> don't store & show
                return false
            }
            
            // Different or absent message id -> store & show
            $notificationsCache.withLock { $0.qms[model.threadID] = model.messageID }
            
            let isSystemEvent = model.threadID == 0
            let notificationType: NotificationsSettings2 = isSystemEvent ? .qmsSystemEvents : .qms
            
            // Check if current qms type is enabled in app settings
            guard appSettings.notifications2.contains(notificationType) else {
                return false
            }
            
            // Check if current context allows for push to show up
            guard processContext(item: item, context: context) else {
                return false
            }
            
            return true
            
        case let .newTopic(model):
            // Check for last post date in forum
            let cachedLastPostDate = notificationsCache.forums[model.forumID]

            guard cachedLastPostDate != model.lastPostDate.asInt() else {
                // Same last post date -> don't store
                return false
            }
            
            // Different or absent last post date -> store
            $notificationsCache.withLock { $0.forums[model.forumID] = model.lastPostDate.asInt() }
            
            // Check for app notification settings
            switch appSettings.notifications2.favoritesMode {
            case .all:
                break
            case .important:
                guard model.favoriteState.isPinned else {
                    return false
                }
            case .disabled:
                return false
            }
            
            // Check for notification show type
            switch model.favoriteState.notificationKind.kind {
            case .always:
                break
            case .once:
                // TODO: Must be cleared when visiting forum?
                guard cachedLastPostDate == nil else {
                    return false
                }
            case .doNot:
                return false
            }
            
            // Check if current context allows for push to show up
            guard processContext(item: item, context: context) else {
                return false
            }
            
            return true
            
        case let .newPost(model):
            // Check for last post date in topic
            let cachedLastPostDate = notificationsCache.topics[model.topicID]
            
            guard cachedLastPostDate != model.lastPostDate.asInt() else {
                // Same last post date -> don't store
                return false
            }
            
            // Different or absent last post date -> store
            $notificationsCache.withLock { $0.topics[model.topicID] = model.lastPostDate.asInt() }
            
            // Check for app notification settings
            switch appSettings.notifications2.favoritesMode {
            case .all:
                break
            case .important:
                guard model.favoriteState.isPinned else {
                    return false
                }
            case .disabled:
                return false
            }
            
            // Check for notification show type
            switch model.favoriteState.notificationKind.kind {
            case .always:
                break
            case .once:
                // TODO: Must be cleared when visiting topic?
                guard cachedLastPostDate == nil else {
                    return false
                }
            case .doNot:
                return false
            }
            
            // Check if current context allows for push to show up
            guard processContext(item: item, context: context) else {
                return false
            }
            
            return true
            
        case .forumMention, .siteMention:
            // Check for app notification settings
            guard appSettings.notifications2.contains(.mentions) else {
                return false
            }
            
            // Check if current context allows for push to show up
            guard processContext(item: item, context: context) else {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Clear
    
    func clearNotifications(item: PDANotification) async {
        let notifications = await center.deliveredNotifications()
        let identifiers: [String] = notifications.compactMap { notification -> String? in
            guard let identifier = notification.request.pdaIdentifier,
                  identifier.primaryID == item.primaryID,
                  identifier.kind == item.identifier.kind else {
                return nil
            }
            return notification.request.identifier
        }
        center.removeDeliveredNotifications(withIdentifiers: identifiers)
    }
    
    // MARK: - Build
    
    func buildNotificationContent(item: PDANotificationDomain) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.sound = .default
        
        switch item {
        case let .qmsMessage(model):
            content.title = model.member.name.convertCodes()
            content.body = String(localized: "notifications.qmsMessage.thread:\(model.threadTitle).count:\(model.unreadCount)", bundle: .module)
            
        case let .newTopic(model):
            content.title = String(localized: "notifications.newTopic.title", bundle: .module)
            content.body = model.forumTitle
            
        case let .newPost(model):
            content.title = model.favoriteState.notificationKind.hasHatUpdate
            ? String(localized: "notifications.newPost.hatUpdate", bundle: .module)
            : String(localized: "notifications.newPost.title.memberName:\(model.member.name.convertCodes())", bundle: .module)
            content.body = model.topicTitle.convertCodes()
            
        case let .forumMention(model):
            content.title = String(localized: "notifications.forumMention.title:\(model.topicTitle)", bundle: .module)
            content.body = String(localized: "notifications.mention.memberName:\(model.member.name)", bundle: .module)
            
        case let .siteMention(model):
            content.title = String(localized: "notifications.siteMention.title:\(model.postTitle)", bundle: .module)
            content.body = String(localized: "notifications.mention.memberName:\(model.member.name)", bundle: .module)
        }
        
        return content
    }
    
    // MARK: - Show
    
    func showLocalNotification(identifier: String, content: UNMutableNotificationContent) async {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        do {
            try await center.add(request)
        } catch {
            analytics.capture(error)
        }
    }
}

// MARK: - Extensions

extension UNNotificationRequest {
    var pdaIdentifier: PDANotification.Identifier? {
        PDANotification.Identifier(userInfo: content.userInfo) ?? PDANotification.Identifier(rawValue: identifier)
    }
}

extension Date {
    func asInt() -> Int {
        Int(timeIntervalSince1970)
    }
}
