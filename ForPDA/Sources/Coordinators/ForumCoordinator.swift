//
//  ForumCoordinator.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import UIKit
import XCoordinator

enum ForumRoute: Route {
    case forum
}

final class ForumCoordinator: NavigationCoordinator<ForumRoute> {
    
    init() {
        super.init(initialRoute: .forum)
    }
    
    override func prepareTransition(for route: ForumRoute) -> NavigationTransition {
        switch route {
        case .forum:
            let viewController = ForumFactory.create(with: unownedRouter)
            return .push(viewController)
        }
    }
}
