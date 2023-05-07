//
//  NewsVM.swift
//  ForPDA
//
//  Created by Subvert on 24.12.2022.
//

import Foundation
import Factory

final class NewsVM {
    
    @Injected(\.networkService) private var networkService
    @Injected(\.parsingService) private var parsingService
    
    weak var view: NewsVC?
    
    init(view: NewsVC) {
        self.view = view
    }
    
    func loadArticles(atPage number: Int = 1) {
        Task {
            do {
                let page = try await networkService.getArticles(atPage: number)
                let articles = parsingService.parseArticles(from: page)
                updateArticles(with: articles)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func refreshArticles() {
        Task {
            do {
                let page = try await networkService.getArticles(atPage: 1)
                let articles = parsingService.parseArticles(from: page)
                updateArticles(with: articles, forced: true)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    private func updateArticles(with articles: [Article], forced: Bool = false) {
        DispatchQueue.main.async {
            if forced {
                self.view?.articles = articles
            } else {
                self.view?.articles += articles
            }
            self.view?.myView.tableView.reloadData()
            self.view?.myView.refreshControl.endRefreshing()
            self.view?.myView.refreshButton.isHidden = false
            self.view?.myView.refreshButton.setTitle("ЗАГРУЗИТЬ БОЛЬШЕ", for: .normal)
        }
    }
    
}
