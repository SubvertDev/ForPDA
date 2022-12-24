//
//  NewsVM.swift
//  ForPDA
//
//  Created by Subvert on 24.12.2022.
//

import Foundation

final class NewsVM {
    
    weak var view: NewsVC?
    
    init(view: NewsVC) {
        self.view = view
    }
    
    func loadArticles() {
        Task {
            do {
                let page = try await NetworkManager.shared.getStartPage()
                let articles = DocumentParser.shared.parseArticles(from: page)
                updateArticles(with: articles)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    private func updateArticles(with articles: [Article]) {
        DispatchQueue.main.async {
            self.view?.articles = articles
            self.view?.myView.tableView.reloadData()
            self.view?.myView.refreshControl.endRefreshing()
        }
    }
    
}
