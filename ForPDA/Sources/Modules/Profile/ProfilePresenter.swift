//
//  ProfilePresenter.swift
//  ForPDA
//
//  Created by Subvert on 23.05.2023.
//

import Foundation
import Factory

protocol ProfilePresenterProtocol {
    var user: User? { get }
    
    func getUser() async
    func logout() async
}

final class ProfilePresenter: ProfilePresenterProtocol {
    
    // MARK: - Properties
    
    @Injected(\.userService) private var userService
    @Injected(\.authService) private var authService
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
    
    @MainActor
    func getUser() async {
        guard let user else {
            print("[ERROR] Tried to get user without user data")
            view?.dismissProfile()
            return
        }
        
        do {
            let response = try await userService.user(id: user.id)
            let user = parsingService.parseUser(from: response)
            self.user = user
            
            let userData = try JSONEncoder().encode(user)
            settingsService.setUser(userData)
            
            view?.updateUser(with: user)
        } catch {
            print("[ERROR] Failed to get user \(error)")
            view?.dismissProfile()
        }
    }
    
    @MainActor
    func logout() async {
        guard let key = settingsService.getAuthKey() else {
            print("[ERROR] Failed to retrieve key for profile")
            view?.showError(message: R.string.localizable.somethingWentWrong())
            return
        }
        
        view?.showLoading(true)
        
        do {
            let response = try await authService.logout(key: key)
            let isLoggedIn = parsingService.parseIsLoggedIn(from: response)
            
            if isLoggedIn {
                view?.showError(message: R.string.localizable.somethingWentWrong())
            } else {
                settingsService.logout()
                view?.dismissProfile()
            }
            
        } catch {
            print("[ERROR] Failed to get user \(error)")
            view?.showError(message: R.string.localizable.somethingWentWrong())
        }
        
        view?.showLoading(false)
    }
}
