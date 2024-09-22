//
//  App.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2024.
//

import SwiftUI
import ComposableArchitecture
import AppFeature

// MARK: - Main View

@main
struct ForPDAApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            AppView(store: appDelegate.store)
                .onChange(of: scenePhase) { newScenePhase in
                    appDelegate.store.send(.scenePhaseDidChange(from: scenePhase, to: newScenePhase))
                }
                .onOpenURL { url in
                    appDelegate.store.send(.deeplink(url))
                }
                .tint(.Theme.primary)
        }
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}

// MARK: - App Delegate

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        store.send(.appDelegate(.didFinishLaunching(application)))
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        store.send(.appDelegate(.didRegisterForRemoteNotifications(deviceToken)))
    }
}
