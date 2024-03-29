//
//  SettingsService.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import Foundation
import WebKit

final class SettingsService {
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let savedCookies = "savedCookies"
        static let authKey = "authKey"
        static let userId = "userId"
        static let appTheme = "appTheme"
        static let appNightModeBackgroundColor = "appDarkThemeBackgroundColor"
        static let fastLoadingSystem = "fastLoadingSystem"
        static let showLikesInComments = "showLikesInComments"
        static let isDeeplinking = "isDeeplinking"
    }
    
    // MARK: - Logout
    
    func logout() {
        removeCookies()
        removeUser()
        removeAuthKey()
    }
    
    // MARK: - Cookies
    
    func setCookiesAsData(_ cookies: Data) {
        defaults.set(cookies, forKey: Keys.savedCookies)
    }
    
    func getCookiesAsData() -> Data? {
        return defaults.data(forKey: Keys.savedCookies)
    }
    
    private func removeCookies() {
        defaults.removeObject(forKey: Keys.savedCookies)
        
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        
        DispatchQueue.main.async {
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                WKWebsiteDataStore.default().removeData(
                    ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                    for: records.filter { $0.displayName.contains("4pda") },
                    completionHandler: {  }
                )
            }
        }
    }
    
    // MARK: - Auth Key
    
    func setAuthKey(_ key: String) {
        defaults.set(key, forKey: Keys.authKey)
    }
    
    func getAuthKey() -> String? {
        return defaults.string(forKey: Keys.authKey)
    }
    
    private func removeAuthKey() {
        defaults.removeObject(forKey: Keys.authKey)
    }
    
    // MARK: - User
    
    func setUser(_ user: Data) {
        defaults.set(user, forKey: Keys.userId)
        NotificationCenter.default.post(name: .userDidChange, object: nil)
    }
    
    func getUser() -> Data? {
        return defaults.data(forKey: Keys.userId)
    }
    
    private func removeUser() {
        defaults.removeObject(forKey: Keys.userId)
        NotificationCenter.default.post(name: .userDidChange, object: nil)
    }
    
    // MARK: - App Language
    
    func getAppLanguage() -> AppLanguage {
        let language = Locale.autoupdatingCurrent.languageCode
        return AppLanguage(rawValue: language ?? AppLanguage.ru.rawValue) ?? .ru
    }
    
    // MARK: - App Theme
    
    func setAppTheme(to theme: AppTheme) {
        defaults.set(theme.rawValue, forKey: Keys.appTheme)
    }
    
    func getAppTheme() -> AppTheme {
        let theme = defaults.string(forKey: Keys.appTheme)
        return AppTheme(rawValue: theme ?? AppTheme.auto.rawValue) ?? .auto
    }
    
    // MARK: - App Background Color
    
    func setAppBackgroundColor(to color: AppNightModeBackgroundColor) {
        defaults.set(color.rawValue, forKey: Keys.appNightModeBackgroundColor)
        NotificationCenter.default.post(name: .nightModeBackgroundColorDidChange, object: color)
    }
    
    func getAppBackgroundColor() -> AppNightModeBackgroundColor {
        let backgroundColor = defaults.string(forKey: Keys.appNightModeBackgroundColor)
        return AppNightModeBackgroundColor(rawValue: backgroundColor ?? AppNightModeBackgroundColor.black.rawValue) ?? .black
    }
    
    // MARK: - Loading System
    
    func setFastLoadingSystem(to state: Bool) {
        defaults.set(state, forKey: Keys.fastLoadingSystem)
    }
    
    func getFastLoadingSystem() -> Bool {
        if let show = defaults.value(forKey: Keys.fastLoadingSystem) as? Bool {
            return show
        } else {
            return true // Enabled by default
        }
    }
    
    // MARK: - Show Likes In Comments
    
    func setShowLikesInComments(to state: Bool) {
        defaults.set(state, forKey: Keys.showLikesInComments)
    }
    
    func getShowLikesInComments() -> Bool {
        if let show = defaults.value(forKey: Keys.showLikesInComments) as? Bool {
            return show
        } else {
            return false // Disabled by default
        }
    }
    
    // MARK: - Is Deeplinking
    
    func setIsDeeplinking(to state: Bool) {
        defaults.set(state, forKey: Keys.isDeeplinking)
    }
    
    func getIsDeeplinking() -> Bool {
        if let isDeeplinking = defaults.value(forKey: Keys.isDeeplinking) as? Bool {
            return isDeeplinking
        } else {
            return false
        }
    }
}
