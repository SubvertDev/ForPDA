//
//  NewsVC.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Factory
import SwiftMessages
import SFSafeSymbols

protocol NewsVCProtocol: AnyObject {
    func articlesUpdated()
    func showError()
}

final class NewsVC: PDAViewController<NewsView> {
    
    // MARK: - Properties
    
    @Injected(\.analyticsService) private var analyticsService
    
    private let presenter: NewsPresenterProtocol

    // MARK: - Lifecycle
    
    init(presenter: NewsPresenter) {
        self.presenter = presenter
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myView.delegate = self
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
        
        presenter.loadArticles()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showVersion03UpdateInfo()
    }
    
    // todo Удалить после релиза 0.4
    private func showVersion03UpdateInfo() {
        let updateHasShown = "hasShownVersion03UpdateInfo"
        if !UserDefaults.standard.bool(forKey: updateHasShown) {
            UserDefaults.standard.set(true, forKey: updateHasShown)
            let alert = UIAlertController(
                title: R.string.localizable.update03(),
                message: R.string.localizable.update03Text(),
                preferredStyle: .alert
            )
            let enableAction = UIAlertAction(title: R.string.localizable.update03EnableExtension(), style: .cancel) { _ in
                if let url = URL(string: "App-Prefs:SAFARI&path=WEB_EXTENSIONS/") {
                    UIApplication.shared.open(url)
                }
            }
            let okAction = UIAlertAction(title: R.string.localizable.ok(), style: .default)
            alert.addAction(enableAction)
            alert.addAction(okAction)
            present(alert, animated: true)
        }
    }
}

// MARK: - TableView DataSource

extension NewsVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.articles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ArticleCell.self, for: indexPath)
        cell.set(article: presenter.articles[indexPath.row])
        return cell
    }
}

// MARK: - NewsVC Protocol

extension NewsVC: NewsVCProtocol {
    
    func articlesUpdated() {
        myView.tableView.reloadData()
        myView.refreshControl.endRefreshing()
        myView.refreshButton.isHidden = false
        myView.refreshButton.setTitle(R.string.localizable.loadMore(), for: .normal)
        myView.loadingIndicator.isHidden = true
    }
    
    func showError() {
        myView.loadingIndicator.isHidden = true
        let alert = UIAlertController(
            title: R.string.localizable.error(),
            message: R.string.localizable.somethingWentWrong(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: R.string.localizable.ok(), style: .default))
        present(alert, animated: true)
    }
}

// MARK: - NewsView Delegate

extension NewsVC: NewsViewDelegate {
    func refreshButtonTapped() {
        myView.refreshButton.setTitle(R.string.localizable.loadingDots(), for: .normal)
        presenter.loadArticles()
    }
    
    func refreshControlCalled() {
        presenter.refreshArticles()
    }
}

// MARK: - TableView Delegate

extension NewsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Check if non-skeleton table is shown
        guard presenter.articles.count - 1 >= indexPath.row else { return }
        analyticsService.openArticleEvent(presenter.articles[indexPath.row].url)
        presenter.showArticle(at: indexPath)
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let article = presenter.articles[safe: indexPath.row] else { return nil }
        
        return UIContextMenuConfiguration.make(actions: [
            copyAction(article: article),
            shareAction(article: article),
            reportAction(article: article)
        ])
    }
    
    private func copyAction(article: Article) -> UIAction {
        UIAction.make(title: R.string.localizable.copyLink(), symbol: .doc) { [unowned self] _ in
            UIPasteboard.general.string = article.url
            analyticsService.copyArticleLink(article.url)
            SwiftMessages.showDefault(title: R.string.localizable.copied(), body: "")
        }
    }
    
    private func shareAction(article: Article) -> UIAction {
        UIAction.make(title: R.string.localizable.shareLink(), symbol: .arrowTurnUpRight) { [unowned self] _ in
            let activity = UIActivityViewController(activityItems: [article.url], applicationActivities: nil)
            analyticsService.shareArticleLink(article.url)
            present(activity, animated: true)
        }
    }
    
    private func reportAction(article: Article) -> UIAction {
        UIAction.make(title: R.string.localizable.somethingWrongWithArticle(), symbol: .questionmarkCircle) { [unowned self] _ in
            analyticsService.reportBrokenArticle(article.url)
            SwiftMessages.showDefault(title: R.string.localizable.thanks(), body: R.string.localizable.willFixSoon())
        }
    }
}
