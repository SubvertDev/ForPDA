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
    var articles: [Article] { get }
    
    func loadArticles()
    func refreshArticles()
    
    func showArticle(at indexPath: IndexPath)
}

final class NewsVM: NewsVMProtocol {
    
    // MARK: - Properties
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    
    private var router: UnownedRouter<NewsRoute>
    weak var view: NewsVCProtocol?
    
    private var page = 0
    var articles: [Article] = []
    
    // MARK: - Init
    
    init(router: UnownedRouter<NewsRoute>) {
        self.router = router
    }
    
    // MARK: - Functions
    
    func loadArticles() {
        page += 1
        
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
    }
    
    func refreshArticles() {
        page = 1
        
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
    }
    
    // MARK: - Navigation
    
    func showArticle(at indexPath: IndexPath) {
        let article = articles[indexPath.row]
        router.trigger(.newsDetail(article))
    }
}
