//
//  MenuVC.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//
//

import UIKit
import NukeExtensions

protocol MenuVCProtocol: AnyObject {
    func showDefaultError()
    func reloadData()
}

final class MenuVC: PDAViewController<MenuView> {
    
    // MARK: - Properties
    
    private let viewModel: MenuVMProtocol
    
    // MARK: - Lifecycle
    
    init(viewModel: MenuVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegates()
        configureNavBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    // MARK: - Configure
    
    private func setDelegates() {
        myView.tableView.dataSource = self
        myView.tableView.delegate = self
    }
    
    private func configureNavBar() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}

// MARK: - DataSource & Delegates

extension MenuVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].options.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 60 : 46
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.sections[indexPath.section].options[indexPath.row]
        
        switch model.self {
        case .authCell:
            let cell = tableView.dequeueReusableCell(withClass: MenuAuthCell.self)
            if let user = viewModel.user {
                let imageOptions = ImageLoadingOptions(placeholder: R.image.avatarPlaceholder(),
                                                       failureImage: R.image.avatarPlaceholder())
                NukeExtensions.loadImage(with: URL(string: viewModel.user?.avatarUrl),
                                         options: imageOptions,
                                         into: cell.iconImageView) { _ in }
                cell.titleLabel.text = user.nickname
                cell.subtitleLabel.text = R.string.localizable.goToProfile()
            }
            return cell
            
        case .staticCell(model: let model):
            let cell = tableView.dequeueReusableCell(withClass: MenuSettingsCell.self)
            cell.set(with: model)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = viewModel.sections[indexPath.section].options[indexPath.row]
        switch model.self {
        case .authCell(model: let model):
            model.handler()
            
        case .staticCell(model: let model):
            model.handler()
            
        default:
            break
        }
    }
}

// MARK: - MenuVCProtocol

extension MenuVC: MenuVCProtocol {
    
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
