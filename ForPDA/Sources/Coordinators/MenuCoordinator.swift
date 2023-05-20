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
    
    case news
    case search
    case forum
    
    case settings
}

final class MenuCoordinator: NavigationCoordinator<MenuRoute> {
    
    var tabBarRouter: StrongRouter<HomeRoute>?
    
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
            
        case .news:
            guard let tabBarRouter else { return .none() }
            return .trigger(HomeRoute.news, on: tabBarRouter)
            
        case .search:
            guard let tabBarRouter else { return .none() }
            return .trigger(HomeRoute.search, on: tabBarRouter)

        case .forum:
            guard let tabBarRouter else { return .none() }
            return .trigger(HomeRoute.forum, on: tabBarRouter)

        case .settings:
            let viewController = SettingsFactory.create()
            return .push(viewController)
        }
    }
    
}
