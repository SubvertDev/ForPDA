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
            if TestContext.current == nil {
                AppView(store: appDelegate.store)
                    .onChange(of: scenePhase) { newScenePhase in
                        appDelegate.store.send(.scenePhaseDidChange(from: scenePhase, to: newScenePhase))
                    }
                    .onOpenURL { url in
                        appDelegate.store.send(.deeplink(url))
                    }
                    .tint(Color(.Theme.primary))
            }
        }
        .backgroundTask(.appRefresh(appDelegate.store.notificationsId)) { _ in
            await appDelegate.store.send(.syncUnreadTaskInvoked)
        }
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}
