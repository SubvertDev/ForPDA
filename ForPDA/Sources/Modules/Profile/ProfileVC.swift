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

final class ProfileVC: PDAViewController<ProfileView> {
    
    // MARK: - Properties
    
    private let viewModel: ProfileVMProtocol
    
    // MARK: - Lifecycle
    
    init(viewModel: ProfileVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myView.delegate = self
        viewModel.getUser()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

// MARK: - ProfileVCProtocol

extension ProfileVC: ProfileVCProtocol {
    
    func updateUser(with user: User) {
        DispatchQueue.main.async {
            NukeExtensions.loadImage(with: URL(string: user.avatarUrl), into: self.myView.profileImageView) { _ in }
            self.myView.nameLabel.text = user.nickname
        }
    }
    
    func showError(message: String) {
        DispatchQueue.main.async {
            self.myView.errorMessageLabel.text = message
            self.showLoading(false)
        }
    }
    
    func showLoading(_ state: Bool) {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.isUserInteractionEnabled = !state
            self.navigationController?.navigationBar.tintColor = state ? .gray : .systemBlue
            self.myView.logoutButton.showLoading(state)
        }
    }
    
    func dismissProfile() {
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

// MARK: - ProfileViewDelegate

extension ProfileVC: ProfileViewDelegate {
    func logoutButtonTapped() {
        viewModel.logout()
    }
}
