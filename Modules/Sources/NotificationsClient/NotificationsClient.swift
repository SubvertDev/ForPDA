//
//  NotificationsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.09.2024.
//

import SwiftUI
import ComposableArchitecture
import ParsingClient
import AnalyticsClient
import LoggerClient
import CacheClient
import Models
@preconcurrency import Combine

public enum NotificationEvent: Equatable {
    case site(Int)
    case topic(Int)
    case forum(Int)
    case qms(Int)
    
    public var isTopic: Bool {
        if case .topic = self { return true }
        return false
    }
}

public enum NotificationContext: Equatable, Sendable, CustomStringConvertible {
    case chat(id: Int)
    case favorites
    case mentions
    case topic(id: Int)
    
    public var description: String {
        switch self {
        case .chat(let id):  return "Chat (\(id))"
        case .favorites:     return "Favorites"
        case .mentions:      return "Mentions"
        case .topic(let id): return "Topic (\(id))"
        }
    }
}

@DependencyClient
public struct NotificationsClient: Sendable {
    public var hasPermission: @Sendable () async throws -> Bool
    public var requestPermission: @Sendable () async throws -> Bool
    public var registerForRemoteNotifications: @Sendable () async -> Void
    public var setDeviceToken: @Sendable (Data) -> Void
    public var delegate: @Sendable () -> AsyncStream<String> = { .finished }
    public var processNotification: @Sendable (String) async -> Bool = { _ in false }
    public var showUnreadNotifications: @Sendable (Unread, _ skipCategories: [Unread.Item.Category]) async -> Void
    public var removeNotifications: @Sendable ([Unread.Item.Category], [Int], [TimeInterval]) async -> Void
    public var setNotificationContext: @Sendable (_ context: NotificationContext?) -> Void
    public var eventPublisher: @Sendable () -> AnyPublisher<NotificationEvent, Never> = { Just(.topic(0)).eraseToAnyPublisher() }
    public var unreadPublisher: @Sendable () -> AnyPublisher<Unread, Never> = { Just(.mock).eraseToAnyPublisher() }
    
    public func removeNotifications(categories: [Unread.Item.Category] = [], ids: [Int] = [], timestamps: [TimeInterval] = []) async {
        await removeNotifications(categories, ids, timestamps)
    }
}

extension DependencyValues {
    public var notificationsClient: NotificationsClient {
        get { self[NotificationsClient.self] }
        set { self[NotificationsClient.self] = newValue }
    }
}

extension NotificationsClient: DependencyKey {
    
    public static var liveValue: Self {
        @Dependency(\.analyticsClient) var analyticsClient
        @Dependency(\.cacheClient) var cacheClient
        @Dependency(\.logger[.notifications]) var logger
        
        let eventSubject = PassthroughSubject<NotificationEvent, Never>()
        // TODO: Make proper previewValue
        let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        let startValue = cacheClient.getUnread() ?? .mockEmpty
        let unreadSubject = CurrentValueSubject<Unread, Never>(isPreview ? .mockBadges : startValue)
        
        let center = UNUserNotificationCenter.current()
        let context: LockIsolated<NotificationContext?> = .init(nil)
        
        return NotificationsClient(
            hasPermission: {
                return await center.notificationSettings().authorizationStatus == .authorized
            },
            
            requestPermission: {
                return try await center.requestAuthorization(options: [.badge, .alert, .sound])
            },
            
            registerForRemoteNotifications: {
                await UIApplication.shared.registerForRemoteNotifications()
            },
            
            setDeviceToken: { deviceToken in
                let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                print("Device token: \(token)")
            },
            
            delegate: {
                AsyncStream { continuation in
                    let delegate = Delegate(continuation: continuation)
                    center.delegate = delegate
                    continuation.onTermination = { _ in
                        _ = delegate
                    }
                }
            },
            
            processNotification: { notificationRaw in
                do {
                    let notification = try NotificationParser.parse(from: notificationRaw)
                    
                    enum EventError: Error {
                        case unknownFlag(String)
                        case unknownCase(String)
                    }
                    
                    // TODO: Complete all cases
                    switch notification.category {
                    case .qms:
                        switch notification.flag {
                        case 1:
                            // Last api request was NOT the chat of this message
                            eventSubject.send(.qms(notification.id))
                            
                        case 2:
                            // Last api request was the chat of this message
                            // No need to mark it processed to avoid unread sync
                            return false
                            
                        case 101:
                            // 0 - User is typing text
                            // 1 - User is uploading files
                            // Currently unused
                            return false
                            
                        case 102:
                            // User did read chat fully (not sure)
                            eventSubject.send(.qms(notification.id))
                            // No need to update unread for that
                            return false
                            
                        default:
                            analyticsClient.capture(EventError.unknownFlag(notificationRaw))
                            return false
                        }
                        
                    case .topic:
                        switch notification.flag {
                        case 1:
                            eventSubject.send(.topic(notification.id))
                        case 2:
                            // Last message, unused
                            return false
                        case 3:
                            // User mention, processing in showUnreadNotifications
                            return false
                        case 4:
                            // Hat update
                            eventSubject.send(.topic(notification.id))
                        default:
                            analyticsClient.capture(EventError.unknownFlag(notificationRaw))
                            return false
                        }
                        
                    case .forum:
                        switch notification.flag {
                        case 1:
                            eventSubject.send(.forum(notification.id))
                        case 2:
                            // Silent update, unused
                            return false
                        default:
                            analyticsClient.capture(EventError.unknownFlag(notificationRaw))
                            return false
                        }
                        
                    case .site:
                        if notification.flag == 3 {
                            // Article comment mention
                            eventSubject.send(.site(notification.id))
                        } else if notification.flag == 2 {
                            // Last article comment timestamp, unused
                            return false
                        }
                        
                    case .unknown:
                        analyticsClient.capture(EventError.unknownCase(notificationRaw))
                        return false
                    }
                    
                    return true
                } catch {
                    analyticsClient.capture(error)
                    return false
                }
            },
            
            showUnreadNotifications: { unread, skipCategories in
                @Dependency(\.analyticsClient) var analyticsClient
                @Dependency(\.cacheClient) var cacheClient
                @Shared(.appSettings) var appSettings
                
                unreadSubject.send(unread)
                
                do {
                    @Shared(.appSettings) var appSettings
                    let notifications = appSettings.notifications

                    let badgeCount =
                    (notifications.isQmsEnabled ? unread.qmsUnreadCount : 0) +
                    (notifications.isForumEnabled ? unread.forumCount : 0) +
                    (notifications.isTopicsEnabled ? unread.topicCount : 0) +
                    (notifications.isSiteMentionsEnabled ? unread.siteMentionsCount : 0) +
                    (notifications.isForumMentionsEnabled ? unread.forumMentionsCount : 0)
                    
                    logger.info("Setting app notifications badge to \(badgeCount)")
                    try await center.setBadgeCount(badgeCount)
                } catch {
                    analyticsClient.capture(error)
                }
                
                logger.info("Going to show \(unread.items.count) notifications. Skip categories: \(skipCategories)")
                
                for item in unread.items {
                    // customDump(item)
                    
                    // Checking if category of this notification is disabled in settings
                    guard item.isNotificationEnabled(using: appSettings) else {
                        logger.info("Skipping \(item.id) because it's category \(item.category.rawValue) is disabled in settings")
                        continue
                    }

                    // Checking if we're already processed this notification before
                    switch item.notificationType {
                    case .always:
                        if let timestamp = await cacheClient.getLastTimestampOfUnreadItem(item.id), timestamp == item.timestamp {
                            logger.info("Skipping \(item.id) at \(timestamp) (\(item.category.rawValue)) because it's already processed")
                            continue
                        }
                        await cacheClient.setLastTimestampOfUnreadItem(item.timestamp, item.id)
                    case .once:
                        if let topicId = await cacheClient.getTopicIdOfUnreadItem(item.id), topicId == item.id {
                            logger.info("Skipping \(item.id) (\(item.category.rawValue)) because it's already processed")
                            continue
                        }
                        await cacheClient.setTopicIdOfUnreadItem(item.id)
                    case .doNot:
                        logger.info("Skipping \(item.id) because it's set to not to notify")
                        continue
                    case .unknown:
                        logger.warning("Unknown notification skipping condition")
                        continue
                    }
                    
                    // Checking if notification category should be skipped based on provided values
                    if skipCategories.contains(item.category) {
                        logger.info("Skipping \(item.id) (\(item.category.rawValue)) because it's marked to skip")
                        continue
                    }
                    
                    // Checking for current notification context
                    // If we have a match, skip showing a notification
                    if let currentContext = context.value {
                        switch currentContext {
                        case let .chat(id: id) where item.category == .qms && item.id == id:
                            logger.info("Skipping on context: \(currentContext)")
                            continue
                        case .favorites:
                            break
                        case .mentions where item.category == .forumMention || item.category == .siteMention:
                            logger.info("Skipping on context: \(currentContext)")
                            continue
                        case let .topic(id: id) where item.category == .topic && item.id == id:
                            logger.info("Skipping on context: \(currentContext)")
                            continue
                        default:
                            break
                        }
                    }
                                        
                    let content = UNMutableNotificationContent()
                    content.sound = .default
                    
                    switch item.category {
                    case .qms:
                        content.title = item.authorName.convertCodes()
                        content.body = String(localized: "\(item.name.convertCodes()): \(item.unreadCount) новое сообщение")
                    case .forum:
                        content.title = "Новое на форуме"
                        content.body = item.name
                    case .topic:
                        content.title = item.unreadCount & 4 != 0
                        ? "Обновилась шапка"
                        : "\(item.authorName.convertCodes()) в теме"
                        content.body = item.name
                    case .forumMention:
                        content.title = "Упоминание в теме \(item.name)"
                        content.body = "\(item.authorName.convertCodes()) ссылается на вас"
                    case .siteMention:
                        content.title = "Упоминание в новости \(item.name)"
                        content.body = "\(item.authorName.convertCodes()) ссылается на вас"
                    }
                    
                    let identifier = "\(item.category.rawValue)-\(item.id)-\(item.timestamp)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
                    
                    do {
                        // Deleting notification with same id due to update of last message in topic
                        let identifiers = await center.deliveredNotifications()
                            .compactMap { notification -> String? in
                                guard let raw = notification.request.identifier.split(separator: "-")[safe: 1],
                                      let id = Int(raw),
                                      id == item.id
                                else { return nil }
                                return notification.request.identifier
                            }
                        if !identifiers.isEmpty {
                            logger.info("Removing delivered notifications (sun): \(identifiers)")
                            center.removeDeliveredNotifications(withIdentifiers: identifiers)
                        }
                        
                        logger.info("Showing notification: \"\(content.title) \\n \(content.body)\" (\(identifier))")
                        try await center.add(request)
                    } catch {
                        analyticsClient.capture(error)
                    }
                }
                
                logger.info("Successfully processed notifications")
            },
            
            removeNotifications: { categories, ids, timestamps in
                logger.info("Removing notifications with categories: \(categories)")
                
                // Removing via categories
                // Do we even have pending ones?
                let pending = await center.pendingNotificationRequests()
                let filteredPending = pending.filter { notification in
                    if let prefix = notification.identifier.split(separator: "-").first {
                        return categories
                            .map { String($0.rawValue) }
                            .contains(String(prefix))
                    }
                    return false
                }
                if !filteredPending.isEmpty {
                    center.removePendingNotificationRequests(withIdentifiers: filteredPending.map(\.identifier))
                    logger.warning("Removing PENDING notifications (rn-categories): \(filteredPending.map(\.identifier))")
                }
                
                // Removing via categories
                let delivered = await center.deliveredNotifications()
                let filteredCategoriesDelivered = delivered.filter { notification in
                    if let prefix = notification.request.identifier.split(separator: "-").first {
                        return categories
                            .map { String($0.rawValue) }
                            .contains(String(prefix))
                    }
                    return false
                }
                if !filteredCategoriesDelivered.isEmpty {
                    center.removeDeliveredNotifications(withIdentifiers: filteredCategoriesDelivered.map(\.request.identifier))
                    logger.info("Removing delivered notifications (rn-categories): \(filteredCategoriesDelivered)")
                }
                
                // Removing via ids
                let filteredIdsDelivered = delivered
                    .compactMap { notification -> String? in
                        guard let raw = notification.request.identifier.split(separator: "-")[safe: 1],
                              let id = Int(raw),
                              ids.contains(id) else {
                            return nil
                        }
                        return notification.request.identifier
                    }
                if !filteredIdsDelivered.isEmpty {
                    center.removeDeliveredNotifications(withIdentifiers: filteredIdsDelivered)
                    logger.info("Removing delivered notifications (rn-ids): \(filteredIdsDelivered)")
                }
                
                // Removing via timestamps
                let filteredTimestampsDelivered = delivered
                    .compactMap { notification -> String? in
                        guard let raw = notification.request.identifier.split(separator: "-")[safe: 2],
                              let timestamp = TimeInterval(raw),
                              timestamps.contains(timestamp) else {
                            return nil
                        }
                        return notification.request.identifier
                    }
                if !filteredTimestampsDelivered.isEmpty {
                    center.removeDeliveredNotifications(withIdentifiers: filteredTimestampsDelivered)
                    logger.info("Removing delivered notifications (rn-timestamps): \(filteredTimestampsDelivered)")
                }
            },
            
            setNotificationContext: { c in
                if context.value != c {
                    logger.info("Setting notification context to: \(String(describing: c))")
                    context.withValue { $0 = c }
                }
            },
            
            eventPublisher: {
                return eventSubject.eraseToAnyPublisher()
            },
            
            unreadPublisher: {
                return unreadSubject.eraseToAnyPublisher()
            }
        )
    }
}

extension NotificationsClient {
    fileprivate final class Delegate: NSObject, Sendable, UNUserNotificationCenterDelegate {
        let continuation: AsyncStream<String>.Continuation
        private nonisolated(unsafe) var lastNotificationId: String = ""
        
        init(continuation: AsyncStream<String>.Continuation) {
            self.continuation = continuation
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
            guard lastNotificationId != notification.request.identifier else { return [] }
            lastNotificationId = notification.request.identifier // Hotfix for Apple iOS 18 double notification bug
            return [.badge, .banner, .list, .sound]
        }
        
        @MainActor // Fix for Apple bug
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
            let identifier = response.notification.request.identifier
            try? await Task.sleep(for: .seconds(1))
            continuation.yield(identifier)
        }
    }
}

// This conformances and @MainActor for didRecieve func above is a fix of this bug:
// NSInternalInconsistencyException Call must be made on main thread
// More about it:
// https://stackoverflow.com/questions/73750724/how-can-usernotificationcenter-didreceive-cause-a-crash-even-with-nothing-in
extension UNUserNotificationCenter: @retroactive @unchecked Sendable {}
extension UNNotificationResponse: @retroactive @unchecked Sendable {}

// TODO: Move to shared module
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension Unread.Item {
    func isNotificationEnabled(using settings: AppSettings) -> Bool {
        switch category {
        case .qms:
            return settings.notifications.isQmsEnabled
        case .forum:
            return settings.notifications.isForumEnabled
        case .topic:
            return settings.notifications.isTopicsEnabled
        case .forumMention:
            return settings.notifications.isForumMentionsEnabled
        case .siteMention:
            return settings.notifications.isSiteMentionsEnabled
        }
    }
}
