//
//  WebVC.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.11.2023.
//

import UIKit
import WebKit
import Factory

// MARK: - Beta Version -

final class WebVC: UIViewController {
    
    // MARK: - Views
    
    private lazy var webView: WKWebView = {
        // swiftlint:disable force_cast
        let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
        let webView = sceneDelegate.webView
        webView.navigationDelegate = self
        return webView
        // swiftlint:enable force_cast
    }()
    
    // MARK: - Properties
    
    @Injected(\.settingsService) private var settingsService
    @Injected(\.cookiesService) private var cookiesService
    
    private let request: URLRequest
    private let completion: (() -> Void)
    private var captchaHasLoaded = false
    private lazy var cookieStore = webView.configuration.websiteDataStore.httpCookieStore //WKWebsiteDataStore.default().httpCookieStore
    
    // MARK: - Init
    
    init(request: URLRequest, completion: @escaping (() -> Void)) {
        self.request = request
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if settingsService.getFastLoadingSystem() {
            webView.load(request)
        }
        
        // NotificationCenter.default.addObserver(
        //     self, selector: #selector(cookiesChanged(_:)),
        //     name: .NSHTTPCookieManagerCookiesChanged, object: nil
        // )
    }
    
    // @objc private func cookiesChanged(_ notification: NSNotification) {
    //     print(#function)
    // }
}

// MARK: - WKNavigationDelegate

extension WebVC: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // print(#function)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        let urlString = navigationAction.request.url?.absoluteString ?? "blank"
        
        if captchaHasLoaded {
            if urlString == URL.fourpda.absoluteString {
                await printAmountOfCookies()
                settingsService.setFastLoadingSystem(to: false)
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                dismiss(animated: true) {
                    self.completion()
                }
            }
        } else if urlString.contains("cloudflare") {
            captchaHasLoaded = true
        }
        return .allow
    }
    
    // MARK: Helpers
    
    private func saveCookiesFromWKToHTTP() async {
        for cookie in await cookieStore.allCookies() {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
        await printAmountOfCookies()
    }
    
    private func printAmountOfCookies() async {
        let webCookiesCount = await cookieStore.allCookies().count
        let httpCookiesCount = HTTPCookieStorage.shared.cookies?.count ?? 999
        print("Webview: \(webCookiesCount) | Http: \(httpCookiesCount)")
    }
}
