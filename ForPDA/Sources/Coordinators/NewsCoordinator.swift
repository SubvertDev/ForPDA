//
//  NewsCoordinator.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import UIKit
import XCoordinator

enum NewsRoute: Route {
    case news
    case newsDetail(Article)
    case close
}

final class NewsCoordinator: NavigationCoordinator<NewsRoute> {
    
    init() {
        super.init(initialRoute: .news)
    }
    
    override func prepareTransition(for route: NewsRoute) -> NavigationTransition {
        switch route {
        case .news:
            let viewController = NewsFactory.create(with: unownedRouter)
            return .push(viewController)
            
        case .newsDetail(let article):
            let viewController = ArticleFactory.create(with: article)
            return .push(viewController)
            
        case .close:
            return .dismissToRoot()
        }
    }
    
}
