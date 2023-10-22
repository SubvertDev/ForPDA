//
//  SettingsPresenter.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import UIKit
import Factory

protocol SettingsPresenterProtocol {
    var sections: [MenuSection] { get }
    
    func changeTheme(to theme: AppTheme)
    func changeDarkThemeBackgroundColor(to color: AppDarkThemeBackgroundColor)
    func showNewsFLSSwitchTapped(isOn: Bool)
    func showArticleFLSSwitchTapped(isOn: Bool)
    func showLikesInCommentsSwitchTapped(isOn: Bool)
}

final class SettingsPresenter: SettingsPresenterProtocol {
    
    // MARK: - Properties
    
    @LazyInjected(\.settingsService) private var settingsService
    
    weak var view: SettingsVCProtocol?
    
    private var currentLanguage: String {
        switch settingsService.getAppLanguage() {
        case .ru:   return R.string.localizable.languageRussian()
        case .en:   return R.string.localizable.languageEnglish()
        }
    }
    
     private var currentTheme: String {
        switch settingsService.getAppTheme() {
        case .auto:  return R.string.localizable.automatic()
        case .light: return R.string.localizable.themeLight()
        case .dark:  return R.string.localizable.themeDark()
        }
    }
    
    private var currentAppDarkThemeBackgroundColor: String {
        switch settingsService.getAppBackgroundColor() {
        case .dark:  return R.string.localizable.backgroundDark()
        case .black: return R.string.localizable.backgroundBlack()
        }
    }
    
    private var currentShowLikesInComments: Bool {
        settingsService.getShowLikesInComments()
    }
    
    private var newsUsesFLS: Bool {
        settingsService.getNewsFLS()
    }
    
    private var articleUsesFLS: Bool {
        settingsService.getArticleFLS()
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
                                                      handler: changeDarkThemeBackgroundColor))
        ]),
        
        // News & Comments
        MenuSection(
            title: R.string.localizable.advanced(),
            options: [
                .switchCell(model: SwitchOption(
                    title: R.string.localizable.fastLoadingNews(),
                    isOn: newsUsesFLS, handler: {})
                ),
                .switchCell(model: SwitchOption(
                    title: R.string.localizable.fastLoadingArticle(),
                    isOn: articleUsesFLS, handler: {})
                ),
                .switchCell(model: SwitchOption(
                    title: R.string.localizable.commentsShowLikes(),
                    isOn: currentShowLikesInComments, handler: {})
                )
            ]),
        
        // Account
        MenuSection(title: R.string.localizable.account(), options: [
            .staticCell(model: MenuOption(title: R.string.localizable.signOut(), handler: showDefaultError))
        ]),
        
        // About App
        MenuSection(title: R.string.localizable.aboutApp(), options: [
            // .staticCell(model: MenuOption(title: "Проверить обновления", handler: {})),
            .staticCell(model: MenuOption(title: "\(R.string.localizable.version()) \(version) (\(build))", handler: {}))
        ])
    ]
    
    // MARK: - Public Functions
    
    func changeTheme(to theme: AppTheme) {
        settingsService.setAppTheme(to: theme)
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
            .overrideApplicationThemeStyle(with: theme)
        reloadData()
    }
    
    func changeDarkThemeBackgroundColor(to color: AppDarkThemeBackgroundColor) {
        settingsService.setAppBackgroundColor(to: color)
        reloadData()
    }
    
    func showNewsFLSSwitchTapped(isOn: Bool) {
        settingsService.setNewsFLS(to: isOn)
        reloadData(forceUpdate: false)
    }
    
    func showArticleFLSSwitchTapped(isOn: Bool) {
        settingsService.setArticleFLS(to: isOn)
        reloadData(forceUpdate: false)
    }
    
    func showLikesInCommentsSwitchTapped(isOn: Bool) {
        settingsService.setShowLikesInComments(to: isOn)
        reloadData(forceUpdate: false)
    }
    
    // MARK: - Private Actions
    
    private func changeLanguage() {
        view?.showChangeLanguageSheet()
    }
    
    private func changeTheme() {
        view?.showChangeThemeSheet()
    }
    
    private func changeDarkThemeBackgroundColor() {
        view?.showChangeDarkThemeBackgroundColorSheet()
    }
    
    private func showDefaultError() {
        view?.showDefaultError()
    }
    
    // Refactor this
    
    private func reloadData(forceUpdate: Bool = true) {
        let model = DescriptionOption(
            title: R.string.localizable.language(),
            description: currentLanguage,
            handler: changeLanguage)
        sections[0].options[0] = .descriptionCell(model: model)
        
        let model1 = DescriptionOption(
            title: R.string.localizable.theme(),
            description: currentTheme,
            handler: changeTheme)
        sections[1].options[0] = .descriptionCell(model: model1)
        
        let model2 = DescriptionOption(
            title: R.string.localizable.backgroundNight(),
            description: currentAppDarkThemeBackgroundColor,
            handler: changeDarkThemeBackgroundColor)
        sections[1].options[1] = .descriptionCell(model: model2)
        
        let model3 = SwitchOption(
            title: R.string.localizable.fastLoadingNews(),
            isOn: settingsService.getNewsFLS(),
            handler: {})
        sections[2].options[0] = .switchCell(model: model3)
        
        let model4 = SwitchOption(
            title: R.string.localizable.fastLoadingArticle(),
            isOn: settingsService.getArticleFLS(),
            handler: {})
        sections[2].options[1] = .switchCell(model: model4)
        
        let model5 = SwitchOption(
            title: R.string.localizable.commentsShowLikes(),
            isOn: settingsService.getShowLikesInComments(),
            handler: {})
        sections[2].options[2] = .switchCell(model: model5)
        
        if forceUpdate {
            view?.reloadData()
        }
    }
}
