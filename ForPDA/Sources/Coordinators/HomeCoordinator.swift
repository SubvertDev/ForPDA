//
//  AppCoordinator.swift
//  ForPDA
//
//  Created by Subvert on 09.05.2023.
//

import UIKit
import SFSafeSymbols
import XCoordinator

enum HomeRoute: Route {
    case news
    case search
    case forum
    case menu
}

final class HomeCoordinator: TabBarCoordinator<HomeRoute> {
    
    // MARK: - Properties
    
    private let newsRouter: StrongRouter<NewsRoute>
    private let searchRouter: StrongRouter<SearchRoute>
    private let forumRouter: StrongRouter<ForumRoute>
    private let menuRouter: StrongRouter<MenuRoute>
    
    // MARK: - Convenience Init
    
    convenience init() {
        let newsCoordinator = NewsCoordinator()
        let searchCoordinator = SearchCoordinator()
        let forumCoordinator = ForumCoordinator()
        let menuCoordinator = MenuCoordinator()
        
        self.init(newsRouter: newsCoordinator.strongRouter,
                  searchRouter: searchCoordinator.strongRouter,
                  forumRouter: forumCoordinator.strongRouter,
                  menuRouter: menuCoordinator.strongRouter)
        
        menuCoordinator.tabBarRouter = strongRouter
        
        configureNavigationCoordinator(newsCoordinator, title: R.string.localizable.news(), image: .newspaperFill)
        configureNavigationCoordinator(searchCoordinator, title: R.string.localizable.search(), image: .magnifyingglass)
        configureNavigationCoordinator(forumCoordinator, title: R.string.localizable.forum(), image: .bubbleLeftAndBubbleRightFill)
        configureNavigationCoordinator(menuCoordinator, title: R.string.localizable.menu(), image: .listDash)
    }
    
    // MARK: - Init
    
    init(newsRouter: StrongRouter<NewsRoute>,
         searchRouter: StrongRouter<SearchRoute>,
         forumRouter: StrongRouter<ForumRoute>,
         menuRouter: StrongRouter<MenuRoute>) {
        self.newsRouter = newsRouter
        self.searchRouter = searchRouter
        self.forumRouter = forumRouter
        self.menuRouter = menuRouter
        
        let tabBarController = PDATabBarController()
        super.init(rootViewController: tabBarController,
                   tabs: [newsRouter, searchRouter, forumRouter, menuRouter],
                   select: newsRouter)
    }
    
    // MARK: - Prepare Transition
    
    override func prepareTransition(for route: HomeRoute) -> TabBarTransition {
        switch route {
        case .news:     return .select(newsRouter)
        case .search:   return .select(searchRouter)
        case .forum:    return .select(forumRouter)
        case .menu:     return .select(menuRouter)
        }
    }
    
    // MARK: - Helpers
    
    private func configureNavigationCoordinator(_ coordinator: any Coordinator, title: String, image: SFSymbol) {
        coordinator.rootViewController.tabBarItem.title = title
        coordinator.rootViewController.tabBarItem.image = UIImage(systemSymbol: image)
        coordinator.rootViewController.tabBarItem.selectedImage = UIImage(systemSymbol: image)
            .withTintColor(.label, renderingMode: .alwaysOriginal)
    }
}
