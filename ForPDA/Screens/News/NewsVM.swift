//
//  NewsVM.swift
//  ForPDA
//
//  Created by Subvert on 24.12.2022.
//
//  swiftlint:disable unused_capture_list

import Foundation
import Factory
import XCoordinator

protocol NewsVMProtocol {
    func loadArticles()
    func refreshArticles()
    
    func showArticle(at indexPath: IndexPath)
}

final class NewsVM: NewsVMProtocol {
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    
    private var router: UnownedRouter<NewsRoute>?
    weak var view: NewsVCProtocol?
    
    var articles: [Article] = []
    var page = 0
    
    init(router: UnownedRouter<NewsRoute>?) {
        self.router = router
    }
    
    func loadArticles() {
        page += 1
        
        networkService.getArticles(page: page) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                articles += parsingService.parseArticles(from: response)
                view?.articlesUpdated()
                
            case .failure:
                view?.showError()
            }
        }
    }
    
    func refreshArticles() {
        page = 1
        
        networkService.getArticles(page: page) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                articles = self.parsingService.parseArticles(from: response)
                view?.articlesUpdated()
                
            case .failure:
                view?.showError()
            }
        }
    }
    
    // MARK: - Navigation
    
    func showArticle(at indexPath: IndexPath) {
        let article = articles[indexPath.row]
        router?.trigger(.newsDetail(article))
    }
    
}
