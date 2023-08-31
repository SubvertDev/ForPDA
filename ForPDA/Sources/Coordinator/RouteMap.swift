//
//  RouteMap.swift
//  ForPDA
//
//  Created by Subvert on 13.08.2023.
//
//  swiftlint:disable all

import UIKit
import RouteComposer

protocol RouteMapProtocol {
    
}

struct RouteMap: RouteMapProtocol {
    
    // MARK: - [TabBar]
        
    static var tabBarScreen: DestinationStep<PDATabBarController, Any?> {
        StepAssembly(
            finder: ClassFinder(), // В чем разница с <PDATabBarController, Any?>(options: .current, startingPoint: .root)?
            factory: CompleteFactoryAssembly(factory: PDATabBarControllerFactory<PDATabBarController, Any?>())
                .with(createNewsWithNavigationFactory(), using: PDATabBarController.add())
                .with(createForumWithNavigationFactory(), using: PDATabBarController.add())
                .with(createMenuWithNavigationFactory(), using: PDATabBarController.add())
                .assemble())
        .using(GeneralAction.replaceRoot())
        .from(GeneralStep.root())
        .assemble()
    }
    
    // MARK: - [News]
    
    static var newsScreen: DestinationStep<NewsVC, Any?> {
        StepAssembly(
            finder: ClassFinder<NewsVC, Any?>(),
            factory: NilFactory())
        .from(tabBarScreen)
        .assemble()
    }
    
    // MARK: Article
    
    static var articleScreen: DestinationStep<ArticleVC, Article> {
        StepAssembly(
            finder: ClassFinder<ArticleVC, Article>(),
            factory: ArticleFactory())
        .using(UINavigationController.push())
        .from(newsScreen.expectingContainer())
        .assemble()
    }
    
    // MARK: - [Forum]
    
    static var forumScreen: DestinationStep<ForumVC, Any?> {
        StepAssembly(finder: ClassFinder<ForumVC, Any?>(),
                     factory: NilFactory())
        .from(tabBarScreen)
        .assemble()
    }
    
    // MARK: - [Menu]
    
    static var menuScreen: DestinationStep<MenuVC, Any?> {
        StepAssembly(
            finder: ClassFinder<MenuVC, Any?>(),
            factory: NilFactory())
        .from(tabBarScreen)
        .assemble()
    }
    
    // MARK: Profile
    
    static var profileScreen: DestinationStep<ProfileVC, Any?> {
        StepAssembly(
            finder: ClassFinder(),
            factory: ProfileFactory())
        .adding(LoginInterceptor())
        .using(UINavigationController.push())
        .from(menuScreen.expectingContainer())
//        .from(GeneralStep.custom(using: ClassFinder<UINavigationController, Any?>()))
        .assemble()
    }
    
    // MARK: Settings
    
    static var settingsScreen: DestinationStep<SettingsVC, Any?> {
        StepAssembly(
            finder: ClassFinder(),
            factory: SettingsFactory())
        .using(UINavigationController.push())
        .from(menuScreen.expectingContainer())
        .assemble()
    }
}

// MARK: - LoginConfiguration

struct LoginConfiguration {
    
    static var loginScreen: DestinationStep<LoginVC, Any?> {
        StepAssembly(
            finder: ClassFinder(),
            factory: LoginFactory())
        .using(UINavigationController.push())
        .from(GeneralStep.custom(using: ClassFinder<UINavigationController, Any?>()))
        .assemble()
    }
    
//    static func createLoginWithNavigationFactory() -> CompleteFactory<NavigationControllerFactory<UINavigationController, Any?>> {
//        return CompleteFactoryAssembly(
//            factory: NavigationControllerFactory())
//        .with(LoginFactory(), using: UINavigationController.pushAsRoot())
//        .assemble()
//    }
}

// MARK: - NavCon Factories

extension RouteMap {
    
    static func createNewsWithNavigationFactory() -> CompleteFactory<NavigationControllerFactory<UINavigationController, Any?>> {
        return CompleteFactoryAssembly(
            factory: NavigationControllerFactory())
        .with(NewsFactory(), using: UINavigationController.pushAsRoot())
        .assemble()
    }
    
    static func createForumWithNavigationFactory() -> CompleteFactory<NavigationControllerFactory<UINavigationController, Any?>> {
        return CompleteFactoryAssembly(
            factory: NavigationControllerFactory())
        .with(ForumFactory(), using: UINavigationController.pushAsRoot())
        .assemble()
    }
    
    static func createMenuWithNavigationFactory() -> CompleteFactory<NavigationControllerFactory<UINavigationController, Any?>> {
        return CompleteFactoryAssembly(
            factory: NavigationControllerFactory())
        .with(MenuFactory(), using: UINavigationController.pushAsRoot())
        .assemble()
    }
}
