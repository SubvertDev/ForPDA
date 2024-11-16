//
//  NotificationsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.09.2024.
//

import UIKit
import ComposableArchitecture
import AnalyticsClient
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
    public static let liveValue = Self(
        requestPermission: {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound])
        },
        registerForRemoteNotifications: {
            UIApplication.shared.registerForRemoteNotifications()
        },
        setDeviceToken: { deviceToken in
            let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("Device token: \(token)")
        },
        setNotificationsDelegate: {
            
        },
        showUnreadNotifications: { unread in
            for item in unread.items {
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
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                let request = UNNotificationRequest(identifier: "\(item.id)", content: content, trigger: trigger)
                
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
