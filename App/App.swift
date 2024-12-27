//
//  App.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2024.
//

import SwiftUI
import ComposableArchitecture
import AppFeature
import BackgroundTasks

// Remove after New Year
import Models

// MARK: - Main View

@main
struct ForPDAApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    // Remove after New Year
    @Shared(.appSettings) var appSettings: AppSettings
    @State var backgroundTask: UIBackgroundTaskIdentifier? = nil
    let iconAnimator: IconAnimator
    
    init() {
        self.iconAnimator = IconAnimator(
            numberOfFrames: 90,
            numberOfLoops: 3,
            targetFramesPerSecond: 30,
            shouldRunOnMainThread: _appSettings.animateIconOnMainThread.wrappedValue
        )
    }
    
    var body: some Scene {
        WindowGroup {
            if TestContext.current == nil {
                AppView(store: appDelegate.store)
                    .onChange(of: scenePhase) { newScenePhase in
                        appDelegate.store.send(.scenePhaseDidChange(from: scenePhase, to: newScenePhase))
                        
                        // Remove after New Year
                        if appSettings.animateIcon {
                            switch newScenePhase {
                            case .active:
                                iconAnimator.cancel()
                                endTask()
                            case .background:
                                backgroundTask = UIApplication.shared.beginBackgroundTask()
                                iconAnimator.startAnimation() {
                                    endTask()
                                }
                            default:
                                break
                            }
                        }
                    }
                    .onOpenURL { url in
                        appDelegate.store.send(.deeplink(url))
                    }
                    .tint(.Theme.primary)
            }
        }
        .backgroundTask(.appRefresh(appDelegate.store.notificationsId)) { _ in
            await appDelegate.store.send(.syncUnreadTaskInvoked)
        }
    }
    
    // Remove after New Year
    private func endTask() {
        if let backgroundTask = backgroundTask {
            UIApplication.shared.endBackgroundTask(backgroundTask)
        }
        backgroundTask = nil
    }
}

#Preview {
    AppView(store: Store(initialState: AppFeature.State()) { AppFeature() })
}
