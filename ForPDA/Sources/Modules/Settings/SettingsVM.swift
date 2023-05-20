//
//  SettingsVM.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import UIKit
import Factory

protocol SettingsVMProtocol {
    var sections: [MenuSection] { get }
    
    func changeLanguage(to language: AppLanguage)
    func changeTheme(to theme: AppTheme)
}

final class SettingsVM: SettingsVMProtocol {
    
    // MARK: - Properties
    
    @LazyInjected(\.settingsService) private var settingsService
    
    weak var view: SettingsVCProtocol?
    
    private var currentLanguage: String {
        switch settingsService.getAppLanguage() {
        case .auto: return R.string.localizable.automatic()
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
    
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    
    lazy var sections: [MenuSection] = [
        MenuSection(title: R.string.localizable.general(), options: [
            .descriptionCell(model: DescriptionOption(title: R.string.localizable.language(),
                                                      description: currentLanguage,
                                                      handler: changeLanguage))
        ]),
        
        MenuSection(title: R.string.localizable.appearance(), options: [
            .descriptionCell(model: DescriptionOption(title: R.string.localizable.theme(),
                                                      description: currentTheme,
                                                      handler: changeTheme))
        ]),
        
        //MenuSection(title: "Просмотр тем", options: []),
        
        //MenuSection(title: "Списки", options: []),
        
        MenuSection(title: R.string.localizable.account(), options: [
            .staticCell(model: MenuOption(title: R.string.localizable.signOut(), handler: showDefaultError))
        ]),
        
        MenuSection(title: R.string.localizable.aboutApp(), options: [
            // .staticCell(model: MenuOption(title: "Проверить обновления", handler: {})),
            .staticCell(model: MenuOption(title: "\(R.string.localizable.version()) \(version) (\(build))", handler: {}))
        ])
    ]
    
    // MARK: - Public Functions
    
    func changeLanguage(to language: AppLanguage) {
        settingsService.setAppLanguage(to: language)
        
        let model = DescriptionOption(title: R.string.localizable.language(),
                                      description: currentLanguage,
                                      handler: changeLanguage)
        sections[0].options[0] = .descriptionCell(model: model)
        
        view?.showReloadingAlert()
        view?.reloadData()
    }
    
    func changeTheme(to theme: AppTheme) {
        settingsService.setAppTheme(to: theme)
        
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?
            .overrideApplicationThemeStyle(with: theme)
        
        let model = DescriptionOption(title: R.string.localizable.theme(),
                                      description: currentTheme,
                                      handler: changeTheme)
        sections[1].options[0] = .descriptionCell(model: model)
        
        view?.reloadData()
    }
    
    // MARK: - Private Actions
    
    private func changeLanguage() {
        view?.showChangeLanguageSheet()
    }
    
    private func changeTheme() {
        view?.showChangeThemeSheet()
    }
    
    private func showDefaultError() {
        view?.showDefaultError()
    }
}
