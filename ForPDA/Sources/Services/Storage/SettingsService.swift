//
//  SettingsService.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import Foundation

final class SettingsService {
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let appLanguage = "AppleLanguage"
        static let appLanguages = "AppleLanguages"
        static let appTheme = "appTheme"
    }
    
    // MARK: - App Language
    
    // переписать для поддержки мультиязычности
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
}
