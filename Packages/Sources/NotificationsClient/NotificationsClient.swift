//
//  NotificationsClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.09.2024.
//

import UIKit
import ComposableArchitecture
import Models

@DependencyClient
public struct NotificationsClient: Sendable {
    public var requestPermission: @Sendable () async -> Bool = { true }
    public var setDeviceToken: @Sendable (Data) -> Void
    public var setNotificationsDelegate: @Sendable () -> Void
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
            let center = UNUserNotificationCenter.current()
            return await withCheckedContinuation { continuation in
                center.requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                    if let error {
                        continuation.resume(returning: false)
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        },
        setDeviceToken: { deviceToken in

        },
        setNotificationsDelegate: {
            
        }
    )
}

