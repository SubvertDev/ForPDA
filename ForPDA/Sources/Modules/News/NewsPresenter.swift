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
    
    @Injected(\.newsService) private var newsService
    @Injected(\.parsingService) private var parsingService
    @Injected(\.settingsService) private var settingsService
    
    weak var view: NewsVCProtocol?
    
    private var page = 0
    var articles: [Article] = []
    
    // MARK: - Public Functions
    
//    func loadArticles() {
//        page += 1
//        
//        // Если происходит диплинк не на быстрой загрузке, то используем быструю загрузку
//        // todo переделать
//        let isDeeplinking = settingsService.getIsDeeplinking()
//
//        switch (fastLoadingSystem, isDeeplinking) {
//        case (true, _), (_, true):
//            networkService.getNews(page: page) { [weak self] result in
//                guard let self else { return }
//                switch result {
//                case .success(let response):
//                    articles += parsingService.parseArticles(from: response)
//                    Task { @MainActor in
//                        self.view?.articlesUpdated()
//                    }
//                    
//                case .failure:
//                    DispatchQueue.main.async {
//                        self.view?.showError()
//                    }
//                }
//            }
//            settingsService.setIsDeeplinking(to: false)
//            
//        case (false, _):
//            slowLoad(url: URL.fourpda(page: page))
//        }
//    }
    
    @MainActor
    func loadArticles() async {
        page += 1
        
        do {
            let response = try await newsService.news(page: page)
            articles += parsingService.parseArticles(from: response)
            view?.articlesUpdated()
        } catch {
            view?.showError()
        }
        
        settingsService.setIsDeeplinking(to: false)
    }
    
    @MainActor
    func refreshArticles() async {
        page = 1
        
        do {
            let response = try await newsService.news(page: page)
            articles = parsingService.parseArticles(from: response)
            view?.articlesUpdated()
        } catch {
            view?.showError()
        }
    }
    
    // MARK: - Navigation
    
    func showArticle(at indexPath: IndexPath) {
        let article = articles[indexPath.row]
        try? DefaultRouter().navigate(to: RouteMap.articleScreen, with: article)
    }
    
    func menuButtonTapped() {
        try? DefaultRouter().navigate(to: RouteMap.menuScreen, with: nil)
    }
}
