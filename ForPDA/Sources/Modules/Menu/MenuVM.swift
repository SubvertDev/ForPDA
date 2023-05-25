//
//  MenuVM.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit
import Factory
import SFSafeSymbols
import XCoordinator

protocol MenuVMProtocol {
    var sections: [MenuSection] { get }
    var user: User? { get }
}

final class MenuVM: MenuVMProtocol {
    
    // MARK: - Properties
    
    @LazyInjected(\.settingsService) private var settingsService
    
    private let router: UnownedRouter<MenuRoute>
    
    weak var view: MenuVCProtocol?
    
    lazy var sections: [MenuSection] = [
        MenuSection(options: [
            .authCell(model: MenuOption(title: R.string.localizable.guest(), handler: showLoginOrProfileScreen))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: R.string.localizable.news(),
                                          icon: .newspaperFill, handler: showNewsScreen)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.search(),
                                          icon: .magnifyingglass, handler: showSearchScreen)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.forum(),
                                          icon: .bubbleLeftAndBubbleRightFill, handler: showForumScreen)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.history(),
                                          icon: .clockArrowCirclepath, handler: showDefaultError)),
            
            .staticCell(model: MenuOption(title: R.string.localizable.bookmarks(),
                                          icon: .bookmarkFill, handler: showDefaultError))
            
//            .staticCell(model: MenuOption(title: R.string.localizable.forumRules(),
//                                          icon: .bookFill, handler: {}))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: R.string.localizable.settings(),
                                          icon: .gearshapeFill, handler: showSettingsScreen))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: R.string.localizable.appAuthor(),
                                          icon: .heartFill, handler: showAuthor)),
            
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
    
    init(router: UnownedRouter<MenuRoute>) {
        self.router = router
        
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
        if user != nil {
            router.trigger(.profile)
        } else {
            router.trigger(.login)
        }
    }
    
    private func showNewsScreen() {
        router.trigger(.news)
    }
    
    private func showSearchScreen() {
        router.trigger(.search)
    }
    
    private func showForumScreen() {
        router.trigger(.forum)
    }
    
    private func showSettingsScreen() {
        router.trigger(.settings)
    }
    
}
