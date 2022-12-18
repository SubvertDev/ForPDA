//
//  ArticleVM.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import SwiftSoup

final class ArticleVM {
    
    // let networkManager = NetworkManager.shared
    
    weak var view: ArticleVC!
    
    init(view: ArticleVC) {
        self.view = view
    }
    
    func loadArticle(url: URL) {
        Task {
            do {
                let page = try await NetworkManager.shared.getArticlePage(url: url)
                let elements = DocumentParser.shared.parseArticles(from: page)
                await view.setupElements(elements)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
}
