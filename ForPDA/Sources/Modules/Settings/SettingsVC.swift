//
//  SettingsVC.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import UIKit
import Factory

protocol SettingsVCProtocol: AnyObject {
    func showChangeLanguageSheet()
    func showChangeThemeSheet()
    func showChangeDarkThemeBackgroundColorSheet()
    func showReloadingAlert()
    func reloadData()
    
    func showDefaultError()
}

final class SettingsVC: PDAViewController<SettingsView> {
    
    // MARK: - Properties
    
    @LazyInjected(\.settingsService) private var settingsService

    private let viewModel: SettingsVMProtocol
    
    // MARK: - Lifecycle
    
    init(viewModel: SettingsVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegates()
        configureNavigationBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    // MARK: - Configuration
    
    private func setDelegates() {
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
    }
    
    private func configureNavigationBar() {
        title = R.string.localizable.settings()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

// MARK: - TableView Delegate & DataSource

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sections[section].title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].options.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46
    }
    
    // Refactor this
    // swiftlint:disable cyclomatic_complexity function_body_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.sections[indexPath.section].options[indexPath.row]
        
        switch model.self {
        case .staticCell(model: let model):
            let cell = tableView.dequeueReusableCell(withClass: MenuSettingsCell.self)
            cell.set(with: model)
            if indexPath == [3, 0] { cell.selectionStyle = .none }
            return cell
            
        case .descriptionCell(model: let model):
            let cell = tableView.dequeueReusableCell(withClass: MenuSettingsCell.self)
            cell.set(with: model)
            return cell
            
        case .switchCell(model: let model):
            let cell = tableView.dequeueReusableCell(withClass: SettingsSwitchCell.self)
            cell.set(with: model)
            cell.switchTapped = { [weak self] isOn in
                guard let self else { return }
                
                if !isOn {
                    if indexPath.row == 0 {
                        self.viewModel.showFastLoadingSystemSwitchTapped(isOn: isOn)
                    } else {
                        self.viewModel.showLikesInCommentsSwitchTapped(isOn: isOn)
                    }
                    return
                }
                
                var message = ""
                if model.title.contains("Быстрая") {
                    message = R.string.localizable.fastLoadingSystemWarning()
                } else {
                    message = R.string.localizable.commentsShowLikesWarning()
                }
                
                let alert = UIAlertController(
                    title: R.string.localizable.warning(),
                    message: message,
                    preferredStyle: .alert
                )
                
                let okAction = UIAlertAction(title: R.string.localizable.ok(), style: .default) { _ in
                    if indexPath.row == 0 {
                        self.viewModel.showFastLoadingSystemSwitchTapped(isOn: isOn)
                    } else {
                        self.viewModel.showLikesInCommentsSwitchTapped(isOn: isOn)
                    }
                }
                let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .default) { _ in
                    cell.set(with: model)
                    if indexPath.row == 0 {
                        self.viewModel.showFastLoadingSystemSwitchTapped(isOn: !isOn)
                    } else {
                        self.viewModel.showLikesInCommentsSwitchTapped(isOn: !isOn)
                    }
                }
                
                alert.addAction(okAction)
                alert.addAction(cancelAction)
                
                if isOn {
                    present(alert, animated: true)
                }
            }
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = viewModel.sections[indexPath.section].options[indexPath.row]
        switch model.self {
        case .staticCell(model: let model):
            model.handler()
        case .descriptionCell(model: let model):
            model.handler()
        default:
            break
        }
    }
}

// MARK: - SettingsVCProtocol

extension SettingsVC: SettingsVCProtocol {
    
    func showChangeLanguageSheet() {
        let alert = UIAlertController(title: R.string.localizable.themeChoose(), message: nil, preferredStyle: .actionSheet)
        
        let automaticAction = UIAlertAction(title: R.string.localizable.automatic(), style: .default) { _ in
            guard self.settingsService.getAppLanguage() != AppLanguage.auto else { return }
            self.viewModel.changeLanguage(to: .auto)
        }
        let russianAction = UIAlertAction(title: R.string.localizable.languageRussian(), style: .default) { _ in
            guard self.settingsService.getAppLanguage() != AppLanguage.ru else { return }
            self.viewModel.changeLanguage(to: .ru)
        }
        let englishAction = UIAlertAction(title: R.string.localizable.languageEnglish(), style: .default) { _ in
            guard self.settingsService.getAppLanguage() != AppLanguage.en else { return }
            self.viewModel.changeLanguage(to: .en)
        }
        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)
        
        alert.addAction(automaticAction)
        alert.addAction(russianAction)
        alert.addAction(englishAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func showChangeThemeSheet() {
        let alert = UIAlertController(title: R.string.localizable.themeChoose(), message: nil, preferredStyle: .actionSheet)
        
        let automaticAction = UIAlertAction(title: R.string.localizable.automatic(), style: .default) { _ in
            guard self.settingsService.getAppTheme() != AppTheme.auto else { return }
            self.viewModel.changeTheme(to: .auto)
        }
        let lightAction = UIAlertAction(title: R.string.localizable.themeLight(), style: .default) { _ in
            guard self.settingsService.getAppTheme() != AppTheme.light else { return }
            self.viewModel.changeTheme(to: .light)
        }
        let darkAction = UIAlertAction(title: R.string.localizable.themeDark(), style: .default) { _ in
            guard self.settingsService.getAppTheme() != AppTheme.dark else { return }
            self.viewModel.changeTheme(to: .dark)
        }
        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)
        
        alert.addAction(automaticAction)
        alert.addAction(lightAction)
        alert.addAction(darkAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func showChangeDarkThemeBackgroundColorSheet() {
        let alert = UIAlertController(title: R.string.localizable.backgroundChoose(), message: nil, preferredStyle: .actionSheet)
        
        let darkAction = UIAlertAction(title: R.string.localizable.backgroundDark(), style: .default) { _ in
            guard self.settingsService.getAppBackgroundColor() != AppDarkThemeBackgroundColor.dark else { return }
            self.viewModel.changeDarkThemeBackgroundColor(to: .dark)
        }
        let blackAction = UIAlertAction(title: R.string.localizable.backgroundBlack(), style: .default) { _ in
            guard self.settingsService.getAppBackgroundColor() != AppDarkThemeBackgroundColor.black else { return }
            self.viewModel.changeDarkThemeBackgroundColor(to: .black)
        }
        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)
        
        alert.addAction(darkAction)
        alert.addAction(blackAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    func showReloadingAlert() {
        let alert = UIAlertController(title: R.string.localizable.warning(),
                                      message: R.string.localizable.warningRestartApp(),
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: R.string.localizable.ok(), style: .default) { _ in
            exit(0)
        }
        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    func showDefaultError() {
        let alert = UIAlertController(title: R.string.localizable.whoops(),
                                      message: R.string.localizable.notDoneYet(),
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: R.string.localizable.ok(), style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    func reloadData() {
        myView.tableView.reloadData()
    }
}
