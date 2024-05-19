//
//  SettingsService.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import Foundation
import ComposableArchitecture
import WebKit
import Models

// RELEASE: REDO
private enum Keys: String {
    case savedCookies
    case authKey
    case userId // RELEASE: Rename to user?
    case appTheme
    case appNightModeBackgroundColor
    case fastLoadingSystem
    case showLikesInComments
    case isDeeplinking
}

@DependencyClient
public struct SettingsClient {
    // RELEASE: Make concrete types?
    public var getUser: () -> Data?
    public var setUser: (Data) -> Void
    public var deleteUser: () -> Void
    public var logout: () -> Void
    
    // RELEASE: Make concrete types?
    public var getCookiesData: () -> Data?
    public var setCookiesData: (Data) -> Void
    public var deleteCookies: () -> Void
    
    // RELEASE: Make associated type AuthKey?
    public var getAuthKey: () -> String?
    public var setAuthKey: (String) -> Void
    public var deleteAuthKey: () -> Void
    
    // RELEASE: REDO
    public var getAppLanguage: () -> AppLanguage = { .ru }
    
    public var getAppTheme: () -> AppTheme = { .auto }
    public var setAppTheme: (AppTheme) -> Void
    
    // RELEASE: Rename to AppBackgroundColor?
    public var getAppBackgroundColor: () -> AppNightModeBackgroundColor = { .black }
    public var setAppBackgroundColor: (AppNightModeBackgroundColor) -> Void
    
    public var getFastLoadingSystem: () -> Bool = { true }
    public var setFastLoadingSystem: (Bool) -> Void
    
    public var getShowLikesInComments: () -> Bool = { false }
    public var setShowLikesInComments: (Bool) -> Void
}

public extension DependencyValues {
    var settingsClient: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue }
    }
}

extension SettingsClient: DependencyKey {
        
    public static let liveValue = Self(
        
        // MARK: - User
        getUser: {
            return UserDefaults.standard.data(forKey: Keys.userId.rawValue)
        },
        setUser: { data in
            UserDefaults.standard.set(data, forKey: Keys.userId.rawValue)
            // RELEASE: Handle change?
            //        NotificationCenter.default.post(name: .userDidChange, object: nil)
        },
        deleteUser: {
            UserDefaults.standard.removeObject(forKey: Keys.userId.rawValue)
            // RELEASE: Handle change?
            //        NotificationCenter.default.post(name: .userDidChange, object: nil)
        },
        logout: {
            @Dependency(\.settingsClient) var settingsClient
            settingsClient.deleteCookies()
            settingsClient.deleteUser()
            settingsClient.deleteAuthKey()
        },
        
        // MARK: - Cookies
        
        getCookiesData: {
            return UserDefaults.standard.data(forKey: Keys.savedCookies.rawValue)
        },
        setCookiesData: { data in
            UserDefaults.standard.set(data, forKey: Keys.savedCookies.rawValue)
        },
        deleteCookies: {
            UserDefaults.standard.removeObject(forKey: Keys.savedCookies.rawValue)
            
            HTTPCookieStorage.shared.removeCookies(since: .distantPast)
            
            DispatchQueue.main.async {
                // RELEASE: Make async? Add documentation?
                WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                    WKWebsiteDataStore.default().removeData(
                        ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                        for: records.filter { $0.displayName.contains("4pda") },
                        completionHandler: {  }
                    )
                }
            }
        },
        
        // MARK: - AuthKey
        
        getAuthKey: {
            return UserDefaults.standard.string(forKey: Keys.authKey.rawValue)
        },
        setAuthKey: { key in
            UserDefaults.standard.set(key, forKey: Keys.authKey.rawValue)
        },
        deleteAuthKey: {
            UserDefaults.standard.removeObject(forKey: Keys.authKey.rawValue)
        },
        
        // MARK: - App Language
        
        getAppLanguage: {
            // RELEASE: REDO
            let language = Locale.autoupdatingCurrent.language.languageCode?.identifier
            return AppLanguage(rawValue: language ?? AppLanguage.ru.rawValue) ?? .ru
        },
        
        // MARK: - App Theme
        
        getAppTheme: {
            let theme = UserDefaults.standard.string(forKey: Keys.appTheme.rawValue)
            return AppTheme(rawValue: theme ?? AppTheme.auto.rawValue) ?? .auto
        },
        setAppTheme: { theme in
            UserDefaults.standard.set(theme.rawValue, forKey: Keys.appTheme.rawValue)
        },
        
        // MARK: - App Background Color
        
        getAppBackgroundColor: {
            let backgroundColor = UserDefaults.standard.string(forKey: Keys.appNightModeBackgroundColor.rawValue)
            return AppNightModeBackgroundColor(rawValue: backgroundColor ?? AppNightModeBackgroundColor.black.rawValue) ?? .black
        },
        setAppBackgroundColor: { color in
            UserDefaults.standard.set(color.rawValue, forKey: Keys.appNightModeBackgroundColor.rawValue)
            // RELEASE: Handle change?
//            NotificationCenter.default.post(name: .nightModeBackgroundColorDidChange, object: color)
        },
        
        // MARK: - Fast Loading System
        
        getFastLoadingSystem: {
            return UserDefaults.standard.value(forKey: Keys.fastLoadingSystem.rawValue) as? Bool ?? true
        },
        setFastLoadingSystem: { state in
            UserDefaults.standard.set(state, forKey: Keys.fastLoadingSystem.rawValue)
        },
        
        // MARK: - Show Likes In Comments
        
        getShowLikesInComments: {
            return UserDefaults.standard.value(forKey: Keys.showLikesInComments.rawValue) as? Bool ?? false
        },
        setShowLikesInComments: { state in
            UserDefaults.standard.set(state, forKey: Keys.showLikesInComments.rawValue)
        }
    )
}
