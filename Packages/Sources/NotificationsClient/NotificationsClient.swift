//
//  NotificationsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.09.2024.
//

import UIKit
import ComposableArchitecture
import AnalyticsClient
import LoggerClient
import CacheClient
import Models

@DependencyClient
public struct NotificationsClient: Sendable {
    public var requestPermission: @Sendable () async throws -> Bool
    public var registerForRemoteNotifications: @Sendable () async -> Void
    public var setDeviceToken: @Sendable (Data) -> Void
    public var setNotificationsDelegate: @Sendable () -> Void
    public var showUnreadNotifications: @Sendable (Unread) async -> Void
}

extension DependencyValues {
    public var notificationsClient: NotificationsClient {
        get { self[NotificationsClient.self] }
        set { self[NotificationsClient.self] = newValue }
    }
}

extension NotificationsClient: DependencyKey {
    public static var liveValue: Self {
        @Dependency(\.logger[.notifications]) var logger

        return NotificationsClient(
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
            setNotificationsDelegate: {
                
            },
            showUnreadNotifications: { unread in
                @Dependency(\.cacheClient) var cacheClient
                
                for item in unread.items {
                    // customDump(item)
                    
                    if let timestamp = await cacheClient.getLastTimestampOfUnreadItem(item.id), timestamp == item.timestamp {
                        logger.info("Skipping notification at \(timestamp) of item \(item.id) with category \(item.category.rawValue) because it's already processed")
                        continue
                    }
                    
                    logger.info("Processing notification at \(item.timestamp) of \(item.id) with type \(item.category.rawValue)")
                    await cacheClient.setLastTimestampOfUnreadItem(item.timestamp, item.id)
                    
                    let content = UNMutableNotificationContent()
                    content.sound = .default
                    
                    switch item.category {
                    case .qms:
                        content.title = item.authorName
                        content.body = "\(item.name): \(item.unreadCount) нов\(item.unreadCount == 1 ? "ое" : "ых") сообщения"
                    case .forum:
                        content.title = "Новое на форуме"
                        content.body = item.name
                    case .topic:
                        content.title = "\(item.authorName) в топике"
                        content.body = item.name
                    case .forumMention:
                        content.title = "Упоминание в топике \(item.name)"
                        content.body = "\(item.authorName) ссылается на вас"
                    case .siteMention:
                        content.title = "Упоминание в новости \(item.name)"
                        content.body = "\(item.authorName) ссылается на вас"
                    }
                    
                    let request = UNNotificationRequest(identifier: "\(item.id)", content: content, trigger: nil)
                    
                    do {
                        try await UNUserNotificationCenter.current().add(request)
                    } catch {
                        @Dependency(\.analyticsClient) var analyticsClient
                        analyticsClient.capture(error)
                    }
                }
            }
        )
    }
}
