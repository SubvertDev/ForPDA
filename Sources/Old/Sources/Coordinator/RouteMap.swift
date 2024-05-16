//
//  RouteMap.swift
//  ForPDA
//
//  Created by Subvert on 13.08.2023.
//
//  swiftlint:disable all

import UIKit
import RouteComposer

protocol RouteMapProtocol { }

struct RouteMap: RouteMapProtocol {
    
    // MARK: - [News]
    
    static var newsScreen: DestinationStep<NewsVC, Any?> {
        StepAssembly(
            finder: ClassFinder(),
            factory: NewsFactory()
        )
        .using(PDANavigationController.push())
        .from(SingleContainerStep(
            finder: NilFinder(),
            factory: NavigationControllerFactory<PDANavigationController, Any?>())
        )
        .using(GeneralAction.replaceRoot())
        .from(GeneralStep.root())
        .assemble()
    }
    
    // MARK: Article
    
    static var articlePagesScreen: DestinationStep<ArticlePagesVC, Article> {
        StepAssembly(
            finder: ClassFinder<ArticlePagesVC, Article>(),
            factory: ArticlePagesFactory())
        .using(UINavigationController.push())
        .from(newsScreen.expectingContainer())
        .assemble()
    }
    
    // MARK: - [Menu]
    
    static var menuScreen: DestinationStep<MenuVC, Any?> {
        StepAssembly(
            finder: ClassFinder(),
            factory: MenuFactory())
        .using(UINavigationController.push())
        .from(newsScreen.expectingContainer())
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
