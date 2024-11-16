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
            // QMS
            for chat in unread.qms {
                let content = UNMutableNotificationContent()
                content.title = chat.partnerName
                content.body = "\(chat.dialogName): \(chat.unreadCount) нов\(chat.unreadCount == 1 ? "ое" : "ых") сообщения"
                content.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                
                let request = UNNotificationRequest(identifier: "\(chat.dialogId)", content: content, trigger: trigger)
                
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
