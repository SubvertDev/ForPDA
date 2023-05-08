//
//  NewsVC.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Factory
import SwiftMessages

protocol NewsVCProtocol: AnyObject {
    func articlesUpdated()
    func showError()
}

final class NewsVC: PDAViewController<NewsView> {
    
    // MARK: - Properties
    
    @Injected(\.analyticsService) var analyticsService
    
    private let viewModel: NewsVM

    // MARK: - Lifecycle
    
    init(viewModel: NewsVM) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Новости"
        
        setDelegates()
        viewModel.loadArticles()
    }
    
    // MARK: - Configure VC
    
    private func setDelegates() {
        myView.delegate = self
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
    }
}

// MARK: - View Delegate

extension NewsVC: NewsViewDelegate {
    func refreshButtonTapped() {
        myView.refreshButton.setTitle("Загружаю...", for: .normal)
        viewModel.loadArticles()
    }
    
    func refreshControlCalled() {
        viewModel.refreshArticles()
    }
}

// MARK: - TableView DataSource

extension NewsVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ArticleCell.self, for: indexPath)
        cell.set(article: viewModel.articles[indexPath.row])
        return cell
    }
}

// MARK: - TableView Delegate

extension NewsVC: UITableViewDelegate {
    
    // Estimated size for accurate scroll indicator movement
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350
    }
    
    // Opening next article
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let article = viewModel.articles[indexPath.row]
        analyticsService.openArticleEvent(article.url)
        viewModel.showArticle(article)
    }
    
    // Hiding navigation bar while scrolling
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        let isDecelerating = scrollView.panGestureRecognizer.translation(in: scrollView).y < 0
        navigationController?.setNavigationBarHidden(isDecelerating, animated: true)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let article = viewModel.articles[indexPath.row]
        
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let clipboardImage = UIImage(systemName: "clipboard")
            let copyLinkItem = UIAction(title: "Скопировать ссылку", image: clipboardImage) { [unowned self] _ in
                UIPasteboard.general.string = article.url
                analyticsService.copyArticleLink(article.url)
                SwiftMessages.showDefault(title: "Скопировано", body: "")
            }
            
            let shareImage = UIImage(systemName: "arrowshape.turn.up.right")
            let shareLinkItem = UIAction(title: "Поделиться ссылкой", image: shareImage) { [unowned self] _ in
                let activity = UIActivityViewController(activityItems: [article.url], applicationActivities: nil)
                analyticsService.shareArticleLink(article.url)
                self.present(activity, animated: true)
            }
            
            let questionImage = UIImage(systemName: "questionmark.circle")
            let brokenArticleItem = UIAction(title: "Проблемы со статьей?", image: questionImage) { [unowned self] _ in
                analyticsService.reportBrokenArticle(article.url)
                SwiftMessages.showDefault(title: "Спасибо!", body: "Починим в ближайшее время :)")
            }
            
            return UIMenu(title: "", options: .displayInline, children: [copyLinkItem, shareLinkItem, brokenArticleItem])
        }
        
        return configuration
    }
}

// MARK: NewsVC Protocol

extension NewsVC: NewsVCProtocol {
    
    func articlesUpdated() {
        DispatchQueue.main.async {
            self.myView.tableView.reloadData()
            self.myView.refreshControl.endRefreshing()
            self.myView.refreshButton.isHidden = false
            self.myView.refreshButton.setTitle("ЗАГРУЗИТЬ БОЛЬШЕ", for: .normal)
        }
    }
    
    func showError() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Ошибка!", message: "Что-то пошло не так...", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
}
