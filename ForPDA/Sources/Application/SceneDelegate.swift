//
//  SceneDelegate.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Factory
import XCoordinator
import WebKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    @Injected(\.settingsService) private var settingsService

    private let coordinator = HomeCoordinator().strongRouter
    
    var window: UIWindow?
    
    var webView: WKWebView!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        
        overrideApplicationThemeStyle(with: settingsService.getAppTheme())
        configureWKWebView()
        coordinator.setRoot(for: window!)
    }
    
    private func configureWKWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.tag = 666
        window?.addSubview(webView)
        
        for cookie in HTTPCookieStorage.shared.cookies ?? [] {
            WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) { }

    func sceneDidBecomeActive(_ scene: UIScene) { }

    func sceneWillResignActive(_ scene: UIScene) { }

    func sceneWillEnterForeground(_ scene: UIScene) { }

    func sceneDidEnterBackground(_ scene: UIScene) { }
}

extension SceneDelegate {
    func overrideApplicationThemeStyle(with theme: AppTheme) {
       window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: theme.ordinal())!
    }
}
