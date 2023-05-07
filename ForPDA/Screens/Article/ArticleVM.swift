//
//  ArticleVM.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import Factory

final class ArticleVM {
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    
    weak var view: ArticleVC?
    
    init(view: ArticleVC) {
        self.view = view
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
