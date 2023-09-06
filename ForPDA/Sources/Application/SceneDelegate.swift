//
//  SceneDelegate.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Factory
import RouteComposer
import WebKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    @Injected(\.settingsService) private var settingsService
    
    var window: UIWindow?
    
    var webView: WKWebView!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
        
        overrideApplicationThemeStyle(with: settingsService.getAppTheme())
        configureWKWebView()
        
        if let url = connectionOptions.urlContexts.first?.url {
            // Cold start deeplink
            handleDeeplinkUrl(url)
        } else {
            try? DefaultRouter().navigate(to: RouteMap.tabBarScreen, with: nil)
        }
    }
    
    private func handleDeeplinkUrl(_ url: URL) {
        if url.absoluteString == "forpda://article//" {
            // Если share в браузере не сработал, то открываем новости
            // todo обработать нормально
            try? DefaultRouter().navigate(to: RouteMap.newsScreen, with: nil)
        } else {
            let id = url.absoluteString.components(separatedBy: "article/")[1]
            let url = "https://4pda.to/\(id)"
            let article = Article(url: url, info: nil)
            try? DefaultRouter().navigate(to: RouteMap.articleScreen, with: article)
        }
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
    
    // Opens on existing scene
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleDeeplinkUrl(url)
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
