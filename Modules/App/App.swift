//
//  App.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2024.
//

import SwiftUI
import ComposableArchitecture
import AppFeature
import CacheClient
import Models

// MARK: - Main View

@main
struct ForPDAApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @Dependency(\.cacheClient) private var cacheClient
    
    var body: some Scene {
        WindowGroup {
            if TestContext.current == nil {
                AppView(store: appDelegate.store)
                    .onChange(of: scenePhase) { _, newScenePhase in
                        appDelegate.store.send(.scenePhaseDidChange(from: scenePhase, to: newScenePhase))
                    }
                    .onOpenURL { url in
                        appDelegate.store.send(.deeplink(url))
                    }
                    .tint(Color(.Theme.primary))
            }
        }
        .backgroundTask(.appRefresh(appDelegate.store.notificationsId)) { _ in
            await cacheClient.setBackgroundTaskEntry(BackgroundTaskEntry(stage: .invoked))
            await appDelegate.store.send(.registerBackgroundTask).finish()
            await appDelegate.store.send(.backgroundTaskInvoked).finish()
            await cacheClient.setBackgroundTaskEntry(BackgroundTaskEntry(stage: .finished))
        }
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}
