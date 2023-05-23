//
//  SettingsService.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import Foundation

final class SettingsService {
    
    private let defaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private enum Keys {
        static let savedCookies = "savedCookies"
        static let authKey = "authKey"
        static let userId = "userId"
        static let appLanguage = "AppleLanguage"
        static let appLanguages = "AppleLanguages"
        static let appTheme = "appTheme"
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
    
    // MARK: - New Settings
    
//    enum UserDefaultKeys: String, CaseIterable {
//        case cookies
//        case authKey
//        case user
//        case appLanguage
//        case appLanguages
//        case appTheme
//    }
//    
//    func set<T>(value: T, key: UserDefaultKeys) {
//        defaults.set(value, forKey: key.rawValue)
//    }
//    
//    func get<T>(type: T.Type, forKey: UserDefaultKeys) -> T? {
//        return defaults.object(forKey: forKey.rawValue) as? T
//    }
//    
//    func remove(key: UserDefaultKeys) {
//        defaults.removeObject(forKey: key.rawValue)
//    }
//    
//    func removeAll() {
//        _ = UserDefaultKeys.allCases.map({ remove(key: $0) })
//    }
//    
//    // Codable
//    
//    func setCodable<T: Codable>(_ object: T, key: UserDefaultKeys) {
//        do {
//            let encodedObject = try encoder.encode(object)
//            defaults.set(encodedObject, forKey: key.rawValue)
//        } catch {
//            print("[ERROR] Encoding of \(T.self) failed")
//        }
//    }
//    
//    func getCodable<T: Codable>(forKey key: UserDefaultKeys) -> T? {
//        do {
//            guard let data = defaults.data(forKey: key.rawValue) else {
//                return nil
//            }
//            return try decoder.decode(T.self, from: data)
//        } catch {
//            print("[ERROR] Decoding of \(T.self) failed")
//            return nil
//        }
//    }
}
