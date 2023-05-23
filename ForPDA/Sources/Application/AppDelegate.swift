//
//  AppDelegate.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import SnapKit
import Factory
import Firebase
import Nuke

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    @Injected(\.networkService) private var networkService
    @Injected(\.settingsService) private var settingsService

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.min)
        
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        
        configureCookies()
        
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) { }

}

// MARK: - Extension

extension AppDelegate {
    
    func configureCookies() {
        // We need 3 cookies to authorize: anonymous, member_id, pass_hash
        // There's also __fixmid cookie, but it lasts for a second and then removed
        if let cookies = HTTPCookieStorage.shared.cookies, cookies.count < 3 {
            // Getting saved cookies if present
            if let cookiesData = settingsService.getCookiesAsData() {
                // Decoding custom Cookie class since HTTPCookie doesn't support Codable
                if let cookies = try? JSONDecoder().decode([Cookie].self, from: cookiesData) {
                    // Force-casting Cookie to HTTPCookie and setting them for 4pda.to domain
                    let mappedCookies = cookies.map { $0.httpCookie! }
                    HTTPCookieStorage.shared.setCookies(mappedCookies, for: networkService.baseURL, mainDocumentURL: nil)
                } else {
                    // Deleting saved cookies in defaults if we can't decode them
                    settingsService.removeCookies()
                }
            } else {
                // Deleting all cookies in case we don't have them saved to prevent different sources of truth
                HTTPCookieStorage.shared.removeCookies(since: .distantPast)
            }
        }
    }
}
