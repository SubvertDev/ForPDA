//
//  MenuCoordinator.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import UIKit
import XCoordinator

enum MenuRoute: Route {
    case menu
    // case login
}

final class MenuCoordinator: NavigationCoordinator<MenuRoute> {
    
    init() {
        super.init(initialRoute: .menu)
    }
    
    override func prepareTransition(for route: MenuRoute) -> NavigationTransition {
        switch route {
        case .menu:
            let viewController = MenuFactory.create(with: unownedRouter)
            return .push(viewController)
            
//        case .login:
//            let viewController = LoginFactory.create()
//            return .push(viewController)
        }
    }
    
}
