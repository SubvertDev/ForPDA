//
//  NewsPresenter.swift
//  ForPDA
//
//  Created by Subvert on 24.12.2022.
//
//  swiftlint:disable unused_capture_list

import Foundation
import Factory
import WebKit
import RouteComposer

protocol NewsPresenterProtocol {
    var articles: [Article] { get }
    func loadArticles()
    func refreshArticles()
    func showArticle(at indexPath: IndexPath)
}

final class NewsPresenter: NSObject, NewsPresenterProtocol {
    
    // MARK: - Properties
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    @Injected(\.settingsService) private var settingsService
    
    weak var view: NewsVCProtocol?
    
    private let router = DefaultRouter()
    
    private var page = 0
    var articles: [Article] = []
    
    private var webView: WKWebView?
    private var fastLoadingSystem: Bool {
        settingsService.getFastLoadingSystem()
    }
    private var isSlowRefreshing = false
    
    // MARK: - Init
    
//    init() {
//
//    }
    
    // MARK: - Public Functions
    
    func loadArticles() {
        page += 1
        
        switch fastLoadingSystem {
        case true:
            networkService.getNews(page: page) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let response):
                    articles += parsingService.parseArticles(from: response)
                    view?.articlesUpdated()
                    
                case .failure:
                    view?.showError()
                }
            }
            
        case false:
            slowLoad(url: URL.fourpda(page: page))
        }
    }
    
    func refreshArticles() {
        page = 1
        
        switch fastLoadingSystem {
        case true:
            networkService.getNews(page: page) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let response):
                    articles = self.parsingService.parseArticles(from: response)
                    view?.articlesUpdated()
                    
                case .failure:
                    view?.showError()
                }
            }
            
        case false:
            isSlowRefreshing = true
            slowLoad(url: URL.fourpda)
        }
    }
    
    private func slowLoad(url: URL) {
        if webView == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.configureWebView()
            }
            return
        }
        
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    // MARK: - Navigation
    
    func showArticle(at indexPath: IndexPath) {
        let article = articles[indexPath.row]
        try? router.navigate(to: RouteMap.articleScreen, with: article, animated: true) {_ in }
    }
}

// MARK: - WKNavigationDelegate

extension NewsPresenter: WKNavigationDelegate {
    
    private func configureWebView() {
        if let webView = UIApplication.shared.windows.first?.viewWithTag(666) as? WKWebView {
            self.webView = webView
            webView.navigationDelegate = self
            let request = URLRequest(url: URL.fourpda)
            webView.load(request)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            webView.evaluateJavaScript("document.documentElement.outerHTML") { (doc, err) in
                if let document = doc as? String {
                    if self.isSlowRefreshing {
                        self.page = 1
                        self.articles = []
                        self.isSlowRefreshing = false
                    }
                    self.articles += self.parsingService.parseArticles(from: document)
                    self.view?.articlesUpdated()
                } else {
                    print(err as Any)
                    self.view?.showError()
                }
            }
        }
    }
}
