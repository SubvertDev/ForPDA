//
//  App.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.03.2024.
//

import SwiftUI
import UIKit
import ComposableArchitecture

import SnapKit
import Factory
import Mixpanel
import Sentry
import Nuke

import AppFeature

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let store = Store(
        initialState: AppFeature.State()
    ) {
        AppFeature()
    }
    
//    @Injected(\.settingsService) private var settingsService
//    @Injected(\.cookiesService) private var cookiesService

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        store.send(.appDelegate(.didFinishLaunching))
//        configureMixpanel()
//        configureSentry()
//        configureNuke()
//        configureCookies()
        
        return true
    }
}

// MARK: - Configuration

//extension AppDelegate {
//    
//    // MARK: Mixpanel
//    
//    private func configureMixpanel() {
//        Mixpanel.initialize(
//            token: Secrets.for(key: .MIXPANEL_TOKEN),
//            trackAutomaticEvents: true
//        )
//    }
//    
//    // MARK: Sentry
//    
//    private func configureSentry() {
//        SentrySDK.start { options in
//            options.dsn = Secrets.for(key: .SENTRY_DSN)
//            options.debug = AppScheme.isDebug
//            options.enabled = !AppScheme.isDebug
//            options.tracesSampleRate = 1.0
//            options.diagnosticLevel = .warning
//            options.attachScreenshot = true
//        }
//    }
//    
//    // MARK: Nuke
//
//    private func configureNuke() {
//        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
//    }
//    
//    // MARK: Cookies
//    
//    private func configureCookies() {
//        cookiesService.configureCookies()
//    }
//}


@main
struct ForPDAApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppView(store: appDelegate.store)
        }
    }
}
