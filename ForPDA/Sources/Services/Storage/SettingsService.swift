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
        static let appLanguage = "AppleLanguage"
        static let appLanguages = "AppleLanguages"
        static let appTheme = "appTheme"
        static let appDarkThemeBackgroundColor = "appDarkThemeBackgroundColor"
        static let fastLoadingSystem = "fastLoadingSystem"
        static let showLikesInComments = "showLikesInComments"
    }
    
    // MARK: - Cookies
    
    func setCookiesAsData(_ cookies: Data) {
        defaults.set(cookies, forKey: Keys.savedCookies)
    }
    
    func getCookiesAsData() -> Data? {
        return defaults.data(forKey: Keys.savedCookies)
    }
    
    func removeCookies() {
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
    
    func removeAuthKey() {
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
    
    func removeUser() {
        defaults.removeObject(forKey: Keys.userId)
        NotificationCenter.default.post(name: .userDidChange, object: nil)
    }
    
    // MARK: - App Language
    
    // Refactor to have multilanguage support
    func setAppLanguage(to language: AppLanguage) {
        switch language {
        case .auto:
            defaults.removeObject(forKey: Keys.appLanguage)
            defaults.removeObject(forKey: Keys.appLanguages)
            
        case .ru:
            defaults.set("ru", forKey: Keys.appLanguage)
            defaults.set(["ru", "en"], forKey: Keys.appLanguages)
            
        case .en:
            defaults.set("en", forKey: Keys.appLanguage)
            defaults.set(["en", "ru"], forKey: Keys.appLanguages)
        }
    }
    
    func getAppLanguage() -> AppLanguage {
        let language = defaults.string(forKey: Keys.appLanguage)
        return AppLanguage(rawValue: language ?? AppLanguage.auto.rawValue) ?? .auto
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
    
    func setAppBackgroundColor(to color: AppDarkThemeBackgroundColor) {
        defaults.set(color.rawValue, forKey: Keys.appDarkThemeBackgroundColor)
        NotificationCenter.default.post(name: .darkThemeBackgroundColorDidChange, object: color)
    }
    
    func getAppBackgroundColor() -> AppDarkThemeBackgroundColor {
        let backgroundColor = defaults.string(forKey: Keys.appDarkThemeBackgroundColor)
        return AppDarkThemeBackgroundColor(rawValue: backgroundColor ?? AppDarkThemeBackgroundColor.black.rawValue) ?? .black
    }
    
    // MARK: - Fast Loading System
    
    func setFastLoadingSystem(to state: Bool) {
        defaults.set(state, forKey: Keys.fastLoadingSystem)
    }
    
    func getFastLoadingSystem() -> Bool {
        if let show = defaults.value(forKey: Keys.fastLoadingSystem) as? Bool {
            return show
        } else {
            return false
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
            return true
        }
    }
}
