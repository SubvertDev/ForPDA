//
//  ProfileVC.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//

import UIKit
import Factory
import NukeExtensions

protocol ProfileVCProtocol: AnyObject {
    func updateUser(with user: User)
    func showError(message: String)
    func showLoading(_ state: Bool)
    func dismissProfile()
}

final class ProfileVC: PDAViewControllerWithView<ProfileView> {
    
    // MARK: - Properties
    
    private let presenter: ProfilePresenterProtocol
    
    // MARK: - Lifecycle
    
    init(presenter: ProfilePresenterProtocol) {
        self.presenter = presenter
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myView.delegate = self
        
        Task {
            await presenter.getUser()
        }
    }
}

// MARK: - ProfileVCProtocol

extension ProfileVC: ProfileVCProtocol {
    
    func updateUser(with user: User) {
        NukeExtensions.loadImage(with: URL(string: user.avatarUrl), into: myView.profileImageView) { _ in }
        myView.nameLabel.text = user.nickname
    }
    
    func showError(message: String) {
        myView.errorMessageLabel.text = message
        showLoading(false)
    }
    
    func showLoading(_ state: Bool) {
        navigationController?.navigationBar.isUserInteractionEnabled = !state
        navigationController?.navigationBar.tintColor = state ? .gray : .label
        myView.logoutButton.showLoading(state)
    }
    
    func dismissProfile() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - ProfileViewDelegate

extension ProfileVC: ProfileViewDelegate {
    
    func logoutButtonTapped() {
        Task {
            await presenter.logout()
        }
    }
}
