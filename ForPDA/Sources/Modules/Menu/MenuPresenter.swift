//
//  MenuPresenter.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit
import Factory
import SFSafeSymbols
import RouteComposer

protocol MenuPresenterProtocol {
    var sections: [MenuSection] { get }
    var user: User? { get }
}

final class MenuPresenter: MenuPresenterProtocol {
    
    // MARK: - Properties
    
    @LazyInjected(\.settingsService) private var settingsService
        
    weak var view: MenuVCProtocol?
    
    lazy var sections: [MenuSection] = [
        MenuSection(options: [
            .authCell(model: MenuOption(title: R.string.localizable.guest(), handler: showLoginOrProfileScreen))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: R.string.localizable.history(),
                                          icon: .clockArrowCirclepath, handler: showDefaultError)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.bookmarks(),
                                          icon: .bookmarkFill, handler: showDefaultError))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: R.string.localizable.settings(),
                                          icon: .gearshapeFill, handler: showSettingsScreen))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: R.string.localizable.appAuthor(),
                                          image: R.image.forpda(), handler: showAuthor)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.appDiscussionSite(),
                                          image: R.image.forpda(), handler: showDefaultError)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.telegramNews(),
                                          image: R.image.telegram(), handler: openTelegramNews)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.telegramChat(),
                                          image: R.image.telegram(), handler: openTelegramChat)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.github(),
                                          image: R.image.github(), handler: openGithub))
        ])
    ]
    
    var user: User?
    
    // MARK: - Lifecycle
    
    init() {
        if let userData = settingsService.getUser() {
            user = try? JSONDecoder().decode(User.self, from: userData)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(userDidChange), name: .userDidChange, object: nil)
    }
    
    // MARK: - Notifications
    
    @objc private func userDidChange() {
        if let userData = settingsService.getUser() {
            user = try? JSONDecoder().decode(User.self, from: userData)
        } else {
            user = nil
        }
        DispatchQueue.main.async {
            self.view?.reloadData()
        }
    }
    
    // MARK: - Actions
    
    private func showAuthor() {
        guard let url = URL(string: Links.authorPDA) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openTelegramNews() {
        guard let url = URL(string: Links.telegramNews) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openTelegramChat() {
        guard let url = URL(string: Links.telegramChat) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openGithub() {
        guard let url = URL(string: Links.github) else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func showDefaultError() {
        view?.showDefaultError()
    }
    
    // MARK: - Navigation
    
    func showLoginOrProfileScreen() {
        try? DefaultRouter().navigate(to: RouteMap.profileScreen, with: nil)
    }
    
    private func showSettingsScreen() {
        try? DefaultRouter().navigate(to: RouteMap.settingsScreen, with: nil)
    }
    
}
