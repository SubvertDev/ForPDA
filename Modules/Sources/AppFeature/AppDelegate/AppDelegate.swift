//
//  AppDelegate.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import UIKit
import ComposableArchitecture

public final class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, Sendable {
    
    public let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }
    
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        store.send(.appDelegate(.didFinishLaunching(application)))
        return true
    }
    
    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        store.send(.appDelegate(.didRegisterForRemoteNotifications(deviceToken)))
    }
    
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            store.send(.appDelegate(.didReceiveNotification(response.notification)))
        }
        completionHandler()
    }
    
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // MARK: notify will display, when app in background/closed.
        completionHandler([.alert, .sound]) // add .alert, if you want to see it anyway
    }
}
