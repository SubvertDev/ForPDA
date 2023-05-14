//
//  MenuVM.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit
import SFSafeSymbols
import XCoordinator

protocol MenuVMProtocol {
    var sections: [MenuSection] { get }
    
    func showLoginScreen()
}

final class MenuVM: MenuVMProtocol {
    
    private let router: UnownedRouter<MenuRoute>
    weak var view: MenuVCProtocol?
    
    init(router: UnownedRouter<MenuRoute>) {
        self.router = router
    }
    
    lazy var sections: [MenuSection] = [
        MenuSection(options: [
            .authCell(model: MenuOption(title: "Гость", handler: showDefaultError))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: "Новости", icon: .newspaperFill, handler: showNewsScreen)),
            .staticCell(model: MenuOption(title: "Поиск", icon: .magnifyingglass, handler: showSearchScreen)),
            .staticCell(model: MenuOption(title: "Форум", icon: .bubbleLeftAndBubbleRightFill, handler: showForumScreen)),
            .staticCell(model: MenuOption(title: "История", icon: .clockArrowCirclepath, handler: showDefaultError)),
            .staticCell(model: MenuOption(title: "Закладки", icon: .bookmarkFill, handler: showDefaultError))
            //.staticCell(model: MenuOption(title: "Правила форума", icon: .bookFill, handler: {}))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: "Настройки", icon: .gearshapeFill, handler: showDefaultError))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: "Автор приложения", icon: .heartFill, handler: showAuthor)),
            .staticCell(model: MenuOption(title: "Обсуждение приложения", image: R.image.forpdaSmall(), handler: showDefaultError)),
            .staticCell(model: MenuOption(title: "Новости в Telegram", image: R.image.telegram(), handler: openTelegramChannel)),
            .staticCell(model: MenuOption(title: "Чат в Telegram", image: R.image.telegram(), handler: openTelegramGroup)),
            .staticCell(model: MenuOption(title: "GitHub", image: R.image.github(), handler: showDefaultError))
        ])
    ]
    
    // MARK: - Actions
    
    private func showAuthor() {
        guard let url = URL(string: "https://4pda.to/forum/index.php?showuser=3640948") else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openTelegramChannel() {
        guard let url = URL(string: "https://t.me/forpda_ios") else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func openTelegramGroup() {
        guard let url = URL(string: "https://t.me/forpda_ios_discussions") else { return }
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func showDefaultError() {
        view?.showDefaultError()
    }
    
    // MARK: - Navigation
    
    func showLoginScreen() {
        view?.showDefaultError()
//        router.trigger(.login)
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
    
}
