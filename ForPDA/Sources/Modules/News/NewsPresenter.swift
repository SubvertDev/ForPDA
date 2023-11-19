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
    
//    func loadArticles()
//    func refreshArticles()
    
    //
    func loadArticles() async
    func refreshArticles() async
    //
    func showArticle(at indexPath: IndexPath)
    
    func menuButtonTapped()
}

final class NewsPresenter: NewsPresenterProtocol {
    
    // MARK: - Properties
    
    @Injected(\.newsService) private var network
    @Injected(\.parsingService) private var parser
    @Injected(\.settingsService) private var settings
    
    weak var view: NewsVCProtocol?
    
    private var page = 0
    var articles: [Article] = []
    
    // MARK: - Public Functions
    
    @MainActor
    func loadArticles() async {
        page += 1
        
        do {
            let response = try await network.news(page: page)
            articles += parser.parseArticles(from: response)
            settings.setIsDeeplinking(to: false)
            view?.articlesUpdated()
        } catch {
            view?.showError()
        }
        
        if ArticleChecker.isOn {
            ArticleChecker.start(articles: articles)
        }
    }
    
    @MainActor
    func refreshArticles() async {
        page = 1
        
        do {
            let response = try await network.news(page: page)
            articles = parser.parseArticles(from: response)
            view?.articlesUpdated()
        } catch {
            view?.showError()
        }
    }
    
    // MARK: - Navigation
    
    func showArticle(at indexPath: IndexPath) {
        let article = articles[indexPath.row]
        try? DefaultRouter().navigate(to: RouteMap.articlePagesScreen, with: article)
    }
    
    func menuButtonTapped() {
        try? DefaultRouter().navigate(to: RouteMap.menuScreen, with: nil)
    }
}
