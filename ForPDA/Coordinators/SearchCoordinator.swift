//
//  SearchCoordinator.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import UIKit
import XCoordinator

enum SearchRoute: Route {
    case search
}

final class SearchCoordinator: NavigationCoordinator<SearchRoute> {
    
    init() {
        super.init(initialRoute: .search)
    }
    
    override func prepareTransition(for route: SearchRoute) -> NavigationTransition {
        switch route {
        case .search:
            let viewController = SearchFactory.create(with: unownedRouter)
            return .push(viewController)
        }
    }
}
