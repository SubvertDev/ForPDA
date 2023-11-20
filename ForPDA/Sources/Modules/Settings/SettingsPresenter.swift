//
//  SettingsPresenter.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

// MARK: --
// (todo) (important) !!!NEEDS FULL REFACTORING!!!
// MARK: --

import UIKit
import Factory

protocol SettingsPresenterProtocol {
    var sections: [MenuSection] { get }
    
    func changeTheme(to theme: AppTheme)
    func changeNightModeBackgroundColor(to color: AppNightModeBackgroundColor)
    func fastLoadingSystemSwitchTapped(isOn: Bool)
    func showLikesInCommentsSwitchTapped(isOn: Bool)
}

final class SettingsPresenter: SettingsPresenterProtocol {

    // MARK: - Properties
    
    @Injected(\.settingsService) private var settings
    @Injected(\.analyticsService) private var analytics
    
    weak var view: SettingsVCProtocol?
    
    private var currentLanguage: String {
        switch settings.getAppLanguage() {
        case .ru:   return R.string.localizable.languageRussian()
        case .en:   return R.string.localizable.languageEnglish()
        }
    }
    
     private var currentTheme: String {
        switch settings.getAppTheme() {
        case .auto:  return R.string.localizable.automatic()
        case .light: return R.string.localizable.themeLight()
        case .dark:  return R.string.localizable.themeDark()
        }
    }
    
    private var currentAppDarkThemeBackgroundColor: String {
        switch settings.getAppBackgroundColor() {
        case .dark:  return R.string.localizable.backgroundDark()
        case .black: return R.string.localizable.backgroundBlack()
        }
    }
    
    private var isFLSEnabled: Bool {
        settings.getFastLoadingSystem()
    }
    
    private var currentShowLikesInComments: Bool {
        settings.getShowLikesInComments()
    }
    
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    
    lazy var sections: [MenuSection] = [
        // Language
        MenuSection(title: R.string.localizable.general(), options: [
            .descriptionCell(model: DescriptionOption(title: R.string.localizable.language(),
                                                      description: currentLanguage,
                                                      handler: changeLanguage))
        ]),
        
        // Theme
        MenuSection(title: R.string.localizable.appearance(), options: [
            .descriptionCell(model: DescriptionOption(title: R.string.localizable.theme(),
                                                      description: currentTheme,
                                                      handler: changeTheme)),
            .descriptionCell(model: DescriptionOption(title: R.string.localizable.backgroundNight(),
                                                      description: currentAppDarkThemeBackgroundColor,
                                                      handler: changeNightModeBackgroundColor))
        ]),
        
        // News & Comments
        MenuSection(
            title: R.string.localizable.advanced(),
            options: [
                .descriptionCell(model: DescriptionOption(
                    title: R.string.localizable.safariExtension(),
                    description: R.string.localizable.safariExtensionEnable(),
                    handler: openSafariExtensionPreferences)
                ),
                .switchCell(model: SwitchOption(
                    title: R.string.localizable.fastLoadingSystem(),
                    isOn: isFLSEnabled, 
                    handler: {})
                ),
                .switchCell(model: SwitchOption(
                    title: R.string.localizable.commentsShowLikes(),
                    isOn: currentShowLikesInComments, 
                    handler: {})
                )
            ]),
        
        // Account
//        MenuSection(title: R.string.localizable.account(), options: [
//            .staticCell(model: MenuOption(title: R.string.localizable.signOut(), handler: showDefaultError))
//        ]),
        
        // About App
        MenuSection(title: R.string.localizable.aboutApp(), options: [
            // .staticCell(model: MenuOption(title: "Проверить обновления", handler: {})),
            .staticCell(model: MenuOption(title: "\(R.string.localizable.version()) \(version) (\(build.trimmingCharacters(in: .whitespacesAndNewlines)))", handler: showReleaseOnGithub))
        ])
    ]
    
    private lazy var models = [
        [ // Общие
            DescriptionOption(
                title: R.string.localizable.language(),
                description: currentLanguage,
                handler: changeLanguage
            )
        ],
        [ // Внешний вид
            DescriptionOption(
                title: R.string.localizable.theme(),
                description: currentTheme,
                handler: changeTheme
            ),
            DescriptionOption(
                title: R.string.localizable.backgroundNight(),
                description: currentAppDarkThemeBackgroundColor,
                handler: changeNightModeBackgroundColor
            )
        ],
        [ // Продвинутые
            DescriptionOption(
                title: R.string.localizable.safariExtension(),
                description: R.string.localizable.safariExtensionEnable(),
                handler: openSafariExtensionPreferences
            ),
            SwitchOption(
                title: R.string.localizable.fastLoadingSystem(),
                isOn: settings.getFastLoadingSystem(),
                handler: {}
            ),
            SwitchOption(
                title: R.string.localizable.commentsShowLikes(),
                isOn: settings.getShowLikesInComments(),
                handler: {}
            )
        ]
    ]
    
    // MARK: - Public Functions
    
    func changeTheme(to theme: AppTheme) {
        analytics.event(Event.Settings.themeChanged.rawValue, parameters: ["theme": theme.rawValue])
        settings.setAppTheme(to: theme)
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
            .overrideApplicationThemeStyle(with: theme)
        reloadData()
    }
    
    func changeNightModeBackgroundColor(to color: AppNightModeBackgroundColor) {
        analytics.event(Event.Settings.nightModeChanged.rawValue, parameters: ["color": color.rawValue])
        settings.setAppBackgroundColor(to: color)
        reloadData()
    }
    
    func fastLoadingSystemSwitchTapped(isOn: Bool) {
        analytics.event(Event.Settings.fastLoadingSystemChanged.rawValue, parameters: ["isOn": isOn])
        settings.setFastLoadingSystem(to: isOn)
        reloadData(forceUpdate: false)
    }
    
    func showLikesInCommentsSwitchTapped(isOn: Bool) {
        analytics.event(Event.Settings.showLikesChanged.rawValue, parameters: ["isOn": isOn])
        settings.setShowLikesInComments(to: isOn)
        reloadData(forceUpdate: false)
    }
    
    // MARK: - Private Actions
    
    private func changeLanguage() {
        analytics.event(Event.Settings.languageOpen.rawValue)
        view?.showChangeLanguageSheet()
    }
    
    private func changeTheme() {
        analytics.event(Event.Settings.themeOpen.rawValue)
        view?.showChangeThemeSheet()
    }
    
    private func changeNightModeBackgroundColor() {
        analytics.event(Event.Settings.nightModeOpen.rawValue)
        view?.showChangeDarkThemeBackgroundColorSheet()
    }
    
    private func openSafariExtensionPreferences() {
        analytics.event(Event.Settings.showSafariExtensions.rawValue)
        UIApplication.shared.open(URL(string: "App-Prefs:SAFARI&path=WEB_EXTENSIONS")!)
    }
    
    private func showReleaseOnGithub() {
        analytics.event(Event.Settings.openGithubRelease.rawValue)
        UIApplication.shared.open(URL.githubRelease())
    }
    
    private func showDefaultError() {
        view?.showDefaultError()
    }
    
    private func reloadData(forceUpdate: Bool = true) {
        for (sectionIndex, section) in models.enumerated() {
            for (optionsIndex, option) in section.enumerated() {
                if let descriptionOption = option as? DescriptionOption {
                    sections[sectionIndex].options[optionsIndex] = .descriptionCell(model: descriptionOption)
                } else if let switchOption = option as? SwitchOption {
                    sections[sectionIndex].options[optionsIndex] = .switchCell(model: switchOption)
                }
            }
        }
        
        if forceUpdate {
            view?.reloadData()
        }
    }
}
