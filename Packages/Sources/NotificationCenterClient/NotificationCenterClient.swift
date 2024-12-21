//
//  NotificationCenterClient.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.12.2024.
//

@preconcurrency import Foundation
import ComposableArchitecture

public extension Notification.Name {
    static let favoritesUpdated = Notification.Name("favoritesUpdated")
}

@DependencyClient
public struct NotificationCenterClient: Sendable {
    public var send: @Sendable (_ notification: Notification.Name) -> Void
    public var observe: @Sendable (_ notification: Notification.Name) -> AsyncStream<Void> = { _ in .finished }
}

extension NotificationCenterClient: DependencyKey {
    public static var liveValue: NotificationCenterClient {
        NotificationCenterClient(
            send: { notification in
                NotificationCenter
                    .default
                    .post(name: notification, object: nil)
            },
            observe: { notification in
                AsyncStream { continuation in
                    let observer = NotificationCenter.default.addObserver(
                        forName: notification,
                        object: nil,
                        queue: nil
                    ) { _ in
                        continuation.yield(())
                    }
                    
                    continuation.onTermination = { _ in
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
        )
    }
}

extension DependencyValues {
    public var notificationCenter: NotificationCenterClient {
        get { self[NotificationCenterClient.self] }
        set { self[NotificationCenterClient.self] = newValue }
    }
}
