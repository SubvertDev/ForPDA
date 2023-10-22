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
    @Injected(\.cookiesService) private var cookiesService
    
    var window: UIWindow?
    
    var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.tag = 666
        return webView
    }()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        self.window = UIWindow(windowScene: windowScene)
        
        window?.rootViewController = UIViewController()
        window?.addSubview(webView)
        window?.makeKeyAndVisible()
        
        overrideApplicationThemeStyle(with: settingsService.getAppTheme())
        cookiesService.syncCookies()
        handleNavigation(to: connectionOptions.urlContexts.first?.url)
    }
}

extension SceneDelegate {
    
    // MARK: - Navigation
    
    private func handleNavigation(to url: URL?) {
        if let url {
            // Cold start deeplink
            handleDeeplinkUrl(url)
        } else {
            // Handle 'try?' later (todo)
//            handleDeeplinkUrl(URL(string: "forpda://article/2023/10/21/419630/")!)
            try? DefaultRouter().navigate(to: RouteMap.newsScreen, with: nil)
        }
    }
    
    private func handleDeeplinkUrl(_ url: URL) {
        if url.absoluteString == "forpda://article//" {
            // If share didn't work in browser, fallback to news (also bug with share inside app) (todo)
            try? DefaultRouter().navigate(to: RouteMap.newsScreen, with: nil)
        } else {
            settingsService.setIsDeeplinking(to: true)
            let id = url.absoluteString.components(separatedBy: "article/")[1]
            let url = URL.fourpda.absoluteString + id
            let article = Article(url: url, info: nil)
            try? DefaultRouter().navigate(to: RouteMap.articleScreen, with: article)
        }
    }
    
    // Opens on existing scene
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            handleDeeplinkUrl(url)
        }
    }
    
    // MARK: - Themes
    
    func overrideApplicationThemeStyle(with theme: AppTheme) {
       window?.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: theme.ordinal())!
    }
}
