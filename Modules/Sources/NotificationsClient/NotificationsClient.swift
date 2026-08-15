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
    public var delegate: @Sendable () -> AsyncStream<UNNotificationSnapshot> = { .finished }
    public var processNotification: @Sendable (String) async -> Bool = { _ in false }
    public var showUnreadNotifications: @Sendable (_ unread: Unread, _ skipCategories: [PDANotification.Kind]) async -> Void
    public var removeNotifications: @Sendable ([PDANotification.Kind], [Int], [TimeInterval]) async -> Void
    public var setNotificationContext: @Sendable (_ context: NotificationContext?) -> Void
    public var eventPublisher: @Sendable () -> AnyPublisher<NotificationEvent, Never> = { Just(.topic(0)).eraseToAnyPublisher() }
    public var unreadPublisher: @Sendable () -> AnyPublisher<Unread, Never> = { Just(.mock).eraseToAnyPublisher() }
    
    public func showUnreadNotifications(_ unread: Unread, skipCategories: [PDANotification.Kind] = []) async {
        if !skipCategories.isEmpty {
            assertionFailure("Skip categories was not re-implemented yet")
        }
        await showUnreadNotifications(unread: unread, skipCategories: skipCategories)
    }
    
    public func removeNotifications(categories: [PDANotification.Kind] = [], ids: [Int] = [], timestamps: [TimeInterval] = []) async {
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
        let manager = NotificationManager()
        
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
                // let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                // print("Device token: \(token)")
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
                @Shared(.appSettings) var appSettings
                
                unreadSubject.send(unread)
                
                do {
                    let notifications = appSettings.notifications2

                    var favoritesCount = (notifications.contains(.favorites) || notifications.contains(.favoritesImportant))
                    ? (unread.forumCount + unread.topicCount)
                    : 0
                    
                    // Sometimes we have more favorites in general count than in an array, so we apply min() fix
                    favoritesCount = min(unread.favoritesUnreadCount, favoritesCount)
                    
                    let mentionsCount = notifications.contains(.mentions)
                    ? (unread.siteMentionsCount + unread.forumMentionsCount)
                    : 0
                    
                    let qmsCount = (notifications.contains(.qms) || notifications.contains(.qmsSystemEvents))
                    ? unread.qmsUnreadCount
                    : 0
                    
                    let totalCount = favoritesCount + mentionsCount + qmsCount
                    
                    logger.info("Setting app notifications badge to \(totalCount)")
                    try await center.setBadgeCount(totalCount)
                } catch {
                    analyticsClient.capture(error)
                }
                
                logger.info("Going to show \(unread.items.count) notifications. Skip categories: \(skipCategories)")
                
                await manager.handleLocalNotifications(items: unread.items, context: context.value)
                
                logger.info("Successfully processed local notifications")
            },
            
            removeNotifications: { categories, ids, timestamps in
                
                if !categories.isEmpty {
                    logger.info("Removing notifications with categories: \(categories)")
                    for category in categories {
                        switch category {
                        case .qmsMessage:   await manager.clear(by: .kind(.qmsMessage))
                        case .newTopic:     await manager.clear(by: .kind(.newTopic))
                        case .newPost:      await manager.clear(by: .kind(.newPost))
                        case .forumMention: await manager.clear(by: .kind(.forumMention))
                        case .siteMention:  await manager.clear(by: .kind(.siteMention))
                        }
                    }
                }
                
                if !ids.isEmpty {
                    logger.info("Removing notifications with ids (primaryId): \(ids)")
                    for id in ids {
                        await manager.clear(by: .primaryId(id))
                    }
                }
                
                if !timestamps.isEmpty {
                    logger.info("Removing notifications with timestamps (value): \(timestamps.map(Int.init))")
                    for timestamp in timestamps {
                        await manager.clear(by: .value(Int(timestamp)))
                    }
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

// MARK: - UNUserNotificationCenterDelegate

extension NotificationsClient {
    
    fileprivate final class Delegate: NSObject, Sendable, UNUserNotificationCenterDelegate {
        
        let continuation: AsyncStream<UNNotificationSnapshot>.Continuation
        private nonisolated(unsafe) var lastNotificationId: String = ""
                
        enum NotificationType {
            case socket, remote
        }
        
        init(continuation: AsyncStream<UNNotificationSnapshot>.Continuation) {
            self.continuation = continuation
        }
        
        // Called when notification will be presented in foreground
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            willPresent notification: UNNotification
        ) async -> UNNotificationPresentationOptions {
            guard lastNotificationId != notification.request.identifier else { return [] }
            lastNotificationId = notification.request.identifier // Hotfix for Apple iOS 18 double notification bug
            
            let type: NotificationType = notification.request.content.userInfo.isEmpty ? .socket : .remote
            switch type {
            case .socket:
                return [.banner, .sound, .list]
            case .remote:
                // Remote notifications are currently overriden by locals when in foreground
                return []
            }
        }
        
        // Called when user taps on notification
        @MainActor // Fix for Apple bug
        func userNotificationCenter(
            _ center: UNUserNotificationCenter,
            didReceive response: UNNotificationResponse
        ) async {
            @Dependency(\.analyticsClient) var analytics
            analytics.capturePushNotificationOpened(response)
            
            let snapshot = UNNotificationSnapshot(response.notification)
            continuation.yield(snapshot)
        }
    }
}

// This conformances and @MainActor for didRecieve func above is a fix of this bug:
// NSInternalInconsistencyException Call must be made on main thread
// More about it:
// https://stackoverflow.com/questions/73750724/how-can-usernotificationcenter-didreceive-cause-a-crash-even-with-nothing-in
extension UNUserNotificationCenter: @retroactive @unchecked Sendable {}
extension UNNotificationResponse: @retroactive @unchecked Sendable {}

public struct UNNotificationSnapshot: Sendable {
    public let identifier: String
    public let date: Date
    public let title: String
    public let subtitle: String
    public let body: String
    public let pdaIdentifier: PDANotification.Identifier?

    public init(_ notification: UNNotification) {
        let content = notification.request.content

        identifier = notification.request.identifier
        date = notification.date
        title = content.title
        subtitle = content.subtitle
        body = content.body
        
        pdaIdentifier = .init(userInfo: content.userInfo)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
