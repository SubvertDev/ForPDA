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
    case qms
    
    public var isTopic: Bool {
        if case .topic = self { return true }
        return false
    }
}

@DependencyClient
public struct NotificationsClient: Sendable {
    public var hasPermission: @Sendable () async throws -> Bool
    public var requestPermission: @Sendable () async throws -> Bool
    public var registerForRemoteNotifications: @Sendable () async -> Void
    public var setDeviceToken: @Sendable (Data) -> Void
    public var delegate: @Sendable () -> AsyncStream<String> = { .finished }
    public var processNotification: @Sendable (String) async -> Void
    public var showUnreadNotifications: @Sendable (Unread, _ skipCategories: [Unread.Item.Category]) async -> Void
    public var removeNotifications: @Sendable (_ categories: [Unread.Item.Category]) async -> Void
    public var eventPublisher: @Sendable () -> AnyPublisher<NotificationEvent, Never> = { Just(.topic(0)).eraseToAnyPublisher() }
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
        @Dependency(\.logger[.notifications]) var logger
        
        let subject = PassthroughSubject<NotificationEvent, Never>()

        return NotificationsClient(
            hasPermission: {
                return await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .authorized
            },
            
            requestPermission: {
                return try await UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound])
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
                    UNUserNotificationCenter.current().delegate = delegate
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
                        if notification.flag == 1 {
                            subject.send(.qms)
                            return
                        } else {
                            analyticsClient.capture(EventError.unknownFlag(notificationRaw))
                            return
                        }
                        
                    case .topic:
                        if notification.flag == 1 {
                            subject.send(.topic(notification.id))
                            return
                        } else {
                            analyticsClient.capture(EventError.unknownFlag(notificationRaw))
                            return
                        }
                        
                    case .site:
                        if notification.id == 3 {
                            // Article comment mention
                            subject.send(.site(notification.id))
                            return
                        } else if notification.id == 2 {
                            // Last article comment timestamp, unused
                            return
                        }
                        
                    case .unknown:
                        break
                    }
                    
                    analyticsClient.capture(EventError.unknownCase(notificationRaw))
                } catch {
                    analyticsClient.capture(error)
                }
            },
            
            showUnreadNotifications: { unread, skipCategories in
                @Dependency(\.cacheClient) var cacheClient
                @Shared(.appSettings) var appSettings: AppSettings
                
                logger.info("Going to show \(unread.items.count) notifications.\nSkip categories: \(skipCategories)")
                
                for item in unread.items {
                    // customDump(item)
                    
                    switch item.category {
                    case .qms where !appSettings.notifications.isQmsEnabled:
                        continue
                    case .forum where !appSettings.notifications.isForumEnabled:
                        continue
                    case .topic where !appSettings.notifications.isTopicsEnabled:
                        continue
                    case .forumMention where !appSettings.notifications.isForumMentionsEnabled:
                        continue
                    case .siteMention where !appSettings.notifications.isSiteMentionsEnabled:
                        continue
                    default:
                        break
                    }

                    switch item.notificationType {
                    case .always:
                        if let timestamp = await cacheClient.getLastTimestampOfUnreadItem(item.id), timestamp == item.timestamp {
                            // logger.info("Skipping notification at \(timestamp) of item \(item.id) with category \(item.category.rawValue) because it's already processed")
                            continue
                        }
                        await cacheClient.setLastTimestampOfUnreadItem(item.timestamp, item.id)
                    case .once:
                        if let topicId = await cacheClient.getTopicIdOfUnreadItem(item.id), topicId == item.id {
                            // logger.info("Skipping notification of item \(item.id) with category \(item.category.rawValue) because it's already processed")
                            continue
                        }
                        await cacheClient.setTopicIdOfUnreadItem(item.id)
                    case .doNot:
                        continue
                    case .unknown:
                        continue
                    }
                    
                    if skipCategories.contains(item.category) {
                        // logger.info("Skipping notfication of item \(item.id) with category \(item.category.rawValue) because it's marked to skip")
                        continue
                    }
                    
                    // logger.info("Processing notification at \(item.timestamp) of \(item.id) with type \(item.category.rawValue)")
                    
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
                        content.title = "\(item.authorName.convertCodes()) в теме"
                        content.body = item.name
                    case .forumMention:
                        content.title = "Упоминание в теме \(item.name)"
                        content.body = "\(item.authorName.convertCodes()) ссылается на вас"
                    case .siteMention:
                        content.title = "Упоминание в новости \(item.name)"
                        content.body = "\(item.authorName.convertCodes()) ссылается на вас"
                    }
                    
                    let request = UNNotificationRequest(identifier: "\(item.category.rawValue)-\(item.id)-\(item.timestamp)", content: content, trigger: nil)
                    
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        @Dependency(\.analyticsClient) var analyticsClient
                        analyticsClient.capture(error)
                    }
                }
                
                logger.info("Successfully processed notifications")
            },
            
            removeNotifications: { categories in
                let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
                let filteredPending = pending.filter { notification in
                    if let prefix = notification.identifier.split(separator: "-").first {
                        return categories
                            .map { String($0.rawValue) }
                            .contains(String(prefix))
                    }
                    return false
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: filteredPending.map(\.identifier))
                
                let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
                let filteredDelivered = delivered.filter { notification in
                    if let prefix = notification.request.identifier.split(separator: "-").first {
                        return categories
                            .map { String($0.rawValue) }
                            .contains(String(prefix))
                    }
                    return false
                }
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: filteredDelivered.map(\.request.identifier))
            },
            
            eventPublisher: {
                return subject.eraseToAnyPublisher()
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
