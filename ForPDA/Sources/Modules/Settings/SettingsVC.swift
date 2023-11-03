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

    private let presenter: SettingsPresenterProtocol
    
    // MARK: - Lifecycle
    
    init(presenter: SettingsPresenterProtocol) {
        self.presenter = presenter
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureController()
    }
    
    // MARK: - Configuration
    
    private func configureController() {
        title = R.string.localizable.settings()
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
    }
}

// MARK: - TableView Delegate & DataSource

extension SettingsVC: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return presenter.sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return presenter.sections[section].title
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.sections[section].options.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 46
    }
    
    // Refactor this (todo)
    // swiftlint:disable cyclomatic_complexity function_body_length
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = presenter.sections[indexPath.section].options[indexPath.row]
        
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
                
                // When switching off
                if !isOn {
                    switch indexPath.row {
                    case 0:
                        presenter.fastLoadingSystemSwitchTapped(isOn: isOn)
                    case 1:
                        presenter.showLikesInCommentsSwitchTapped(isOn: isOn)
                    default:
                        break
                    }
                    return
                }
                
                var message = ""
                if model.title.contains("новостей") || model.title.contains("news") {
                    message = R.string.localizable.fastLoadingSystemWarning()
                } else {
                    message = R.string.localizable.commentsShowLikesWarning()
                }
                
                let alert = UIAlertController(
                    title: R.string.localizable.warning(),
                    message: message,
                    preferredStyle: .alert
                )
                
                let okAction = UIAlertAction(title: R.string.localizable.ok(), style: .default) { [weak self] _ in
                    guard let self else { return }
                    if indexPath.row == 0 {
                        presenter.fastLoadingSystemSwitchTapped(isOn: isOn)
                    } else {
                        presenter.showLikesInCommentsSwitchTapped(isOn: isOn)
                    }
                }
                let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .default) { [weak self] _ in
                    guard let self else { return }
                    cell.set(with: model)
                    if indexPath.row == 0 {
                        presenter.fastLoadingSystemSwitchTapped(isOn: !isOn)
                    } else {
                        presenter.showLikesInCommentsSwitchTapped(isOn: !isOn)
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
        
        let model = presenter.sections[indexPath.section].options[indexPath.row]
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
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func showChangeThemeSheet() {
        let alert = UIAlertController(title: R.string.localizable.themeChoose(), message: nil, preferredStyle: .actionSheet)
        
        let automaticAction = UIAlertAction(title: R.string.localizable.automatic(), style: .default) { _ in
            guard self.settingsService.getAppTheme() != AppTheme.auto else { return }
            self.presenter.changeTheme(to: .auto)
        }
        let lightAction = UIAlertAction(title: R.string.localizable.themeLight(), style: .default) { _ in
            guard self.settingsService.getAppTheme() != AppTheme.light else { return }
            self.presenter.changeTheme(to: .light)
        }
        let darkAction = UIAlertAction(title: R.string.localizable.themeDark(), style: .default) { _ in
            guard self.settingsService.getAppTheme() != AppTheme.dark else { return }
            self.presenter.changeTheme(to: .dark)
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
            guard self.settingsService.getAppBackgroundColor() != AppNightModeBackgroundColor.dark else { return }
            self.presenter.changeNightModeBackgroundColor(to: .dark)
        }
        let blackAction = UIAlertAction(title: R.string.localizable.backgroundBlack(), style: .default) { _ in
            guard self.settingsService.getAppBackgroundColor() != AppNightModeBackgroundColor.black else { return }
            self.presenter.changeNightModeBackgroundColor(to: .black)
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
