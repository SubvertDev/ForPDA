//
//  ProfileVM.swift
//  ForPDA
//
//  Created by Subvert on 23.05.2023.
//
// swiftlint:disable force_try

import Foundation
import Factory

protocol ProfileVMProtocol {
    var user: User? { get }
    
    func getUser()
    func logout()
}

final class ProfileVM: ProfileVMProtocol {
    
    // MARK: - Properties
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    @Injected(\.settingsService) private var settingsService
    
    weak var view: ProfileVCProtocol?
    
    var user: User?
    
    // MARK: - Lifecycle
    
    init() {
        guard let userData = settingsService.getUser(),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            print("[ERROR] Tried to open profile without user data / failed decoding")
            view?.dismissProfile()
            return
        }
        self.user = user
    }
    
    // MARK: - Public Functions
    
    func getUser() {
        guard let user else {
            print("[ERROR] Tried to get user without user data")
            view?.dismissProfile()
            return
        }
        networkService.getUser(id: user.id) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                let user = parsingService.parseUser(from: response)
                self.user = user
                
                let userData = try! JSONEncoder().encode(user)
                settingsService.setUser(userData)
                
                view?.updateUser(with: user)
                
            case .failure(let failure):
                print("[ERROR] Failed to get user \(failure.localizedDescription)")
                view?.dismissProfile()
            }
        }
    }
    
    func logout() {
        guard let key = settingsService.getAuthKey() else {
            print("[ERROR] Failed to retrieve key for profile")
            view?.showError(message: R.string.localizable.somethingWentWrong())
            return
        }
        view?.showLoading(true)
        networkService.logout(key: key) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                let isLoggedIn = parsingService.parseIsLoggedIn(from: response)
                
                if isLoggedIn {
                    view?.showError(message: R.string.localizable.somethingWentWrong())
                } else {
                    settingsService.removeCookies()
                    settingsService.removeAuthKey()
                    settingsService.removeUser()
                    view?.dismissProfile()
                }
                
            case .failure(let failure):
                print("[ERROR] Failed to get user \(failure.localizedDescription)")
                view?.showError(message: R.string.localizable.somethingWentWrong())
            }
            view?.showLoading(false)
        }
    }
}
