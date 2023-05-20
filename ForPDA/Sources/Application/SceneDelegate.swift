//
//  SceneDelegate.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Factory
import XCoordinator

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    @Injected(\.settingsService) private var settingsService

    private let coordinator = HomeCoordinator().strongRouter
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        
        overrideApplicationThemeStyle(with: settingsService.getAppTheme())
        
        coordinator.setRoot(for: window!)
    }

    func sceneDidDisconnect(_ scene: UIScene) { }

    func sceneDidBecomeActive(_ scene: UIScene) { }

    func sceneWillResignActive(_ scene: UIScene) { }

    func sceneWillEnterForeground(_ scene: UIScene) { }

    func sceneDidEnterBackground(_ scene: UIScene) { }

    private func configureWKWebView() {
        // let config = WKWebViewConfiguration()
        // config.dataDetectorTypes = []
        // config.suppressesIncrementalRendering = true
        // webView = WKWebView(frame: .zero, configuration: config)
        // webView.tag = 666
        // webView.navigationDelegate = self
        // window.addSubview(webView)
        
        // webView.load(URLRequest(url: URL(string: "https://4pda.to/")!))
    }
}

//extension SceneDelegate: WKNavigationDelegate {
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        print(#function)
//    }
//}

extension SceneDelegate {
    func overrideApplicationThemeStyle(with theme: AppTheme) {
       window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: theme.ordinal())!
    }
}
