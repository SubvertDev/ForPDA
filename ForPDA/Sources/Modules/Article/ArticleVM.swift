//
//  ArticleVM.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import Factory
import XCoordinator

protocol ArticleVMProtocol {
    var article: Article { get }
    
    func loadArticle(url: URL)
}

final class ArticleVM: ArticleVMProtocol {
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    
    //private let router: UnownedRouter<NewsRoute>
    var article: Article
    weak var view: ArticleVC?
    
//    init(router: UnownedRouter<NewsRoute>) {
//        self.router = router
//    }
    init(article: Article) {
        self.article = article
    }
    
    func loadArticle(url: URL) {
        Task {
            do {
                let page = try await networkService.getArticlePage(url: url)
                let elements = parsingService.parseArticle(from: page)
                await view?.configureArticle(elements)
                await view?.configureComments(from: page)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
}
