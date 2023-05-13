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
    
    //weak var coordinator: MenuCoordinator?
    private let router: UnownedRouter<MenuRoute>
    weak var view: MenuVCProtocol?
    
    init(router: UnownedRouter<MenuRoute>) {
        self.router = router
    }
    
    lazy var sections: [MenuSection] = [
        MenuSection(options: [
            .authCell(model: MenuOption(title: "Гость",
                                        icon: UIImage(),
                                        handler: showLoginScreen))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: "Новости",
                                          icon: UIImage(systemSymbol: .newspaperFill),
                                          handler: {})),
            
            .staticCell(model: MenuOption(title: "Поиск",
                                          icon: UIImage(systemSymbol: .magnifyingglass),
                                          handler: {})),
            
            .staticCell(model: MenuOption(title: "Форум",
                                          icon: UIImage(systemSymbol: .bubbleLeftAndBubbleRightFill),
                                          handler: {})),
            
            .staticCell(model: MenuOption(title: "История",
                                          icon: UIImage(systemSymbol: .clockArrowCirclepath),
                                          handler: {})),
            
            .staticCell(model: MenuOption(title: "Закладки",
                                          icon: UIImage(systemSymbol: .bookmarkFill),
                                          handler: {})),
            
            .staticCell(model: MenuOption(title: "Правила форума",
                                          icon: UIImage(systemSymbol: .bookFill),
                                          handler: {}))
        ]),
        
        MenuSection(options: [
            .staticCell(model: MenuOption(title: "Настройки",
                                          icon: UIImage(systemSymbol: .gearshapeFill),
                                          handler: {}))
        ])
    ]
    
    func showLoginScreen() {
//        router.trigger(.login)
    }
    
}
