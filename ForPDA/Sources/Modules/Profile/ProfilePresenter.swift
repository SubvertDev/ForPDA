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
    @Injected(\.parsingService) private var parser
    @Injected(\.settingsService) private var settings
    @Injected(\.analyticsService) private var analytics

    weak var view: ProfileVCProtocol?
    
    var user: User?
    
    // MARK: - Lifecycle
    
    init() {
        guard let userData = settings.getUser(),
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
            let user = parser.parseUser(from: response)
            self.user = user
            
            let userData = try JSONEncoder().encode(user)
            settings.setUser(userData)
            
            view?.updateUser(with: user)
        } catch {
            print("[ERROR] Failed to get user \(error)")
            view?.dismissProfile()
        }
    }
    
    @MainActor
    func logout() async {
        guard let key = settings.getAuthKey() else {
            print("[ERROR] Failed to retrieve key for profile")
            view?.showError(message: R.string.localizable.somethingWentWrong())
            return
        }
        
        view?.showLoading(true)
        
        do {
            let response = try await authService.logout(key: key)
            let isLoggedIn = parser.parseIsLoggedIn(from: response)
            
            if isLoggedIn {
                view?.showError(message: R.string.localizable.somethingWentWrong())
            } else {
                settings.logout()
                view?.dismissProfile()
                analytics.event(Event.Profile.profileLogout.rawValue)
            }
            
        } catch {
            print("[ERROR] Failed to get user \(error)")
            view?.showError(message: R.string.localizable.somethingWentWrong())
        }
        
        view?.showLoading(false)
    }
}
