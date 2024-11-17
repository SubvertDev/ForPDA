//
//  AppDelegate.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 15.11.2024.
//

import UIKit
import ComposableArchitecture

public final class AppDelegate: UIResponder, UIApplicationDelegate, Sendable {
    
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
}
