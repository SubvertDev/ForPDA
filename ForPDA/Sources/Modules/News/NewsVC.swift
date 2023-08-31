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
import SkeletonView

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
        
        configureView()
        presenter.loadArticles()
    }
    
    // MARK: - Configuration
    
    private func configureView() {
        myView.delegate = self
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
        myView.tableView.isSkeletonable = true
        myView.tableView.showAnimatedSkeleton()
    }
}

// MARK: - TableView DataSource

extension NewsVC: SkeletonTableViewDataSource {
    
    // MARK: - Skeleton Table View
    
    func collectionSkeletonView(_ skeletonView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, skeletonCellForRowAt indexPath: IndexPath) -> UITableViewCell? {
        let cell = skeletonView.dequeueReusableCell(withClass: ArticleCell.self, for: indexPath)
        cell.selectionStyle = .none
        return cell
    }
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return String(describing: ArticleCell.self)
    }
    
    // MARK: - Normal Table View
    
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
        DispatchQueue.main.async {
            self.myView.tableView.reloadData()
            self.myView.tableView.hideSkeleton(reloadDataAfter: false)
            self.myView.refreshControl.endRefreshing()
            self.myView.refreshButton.isHidden = false
            self.myView.refreshButton.setTitle(R.string.localizable.loadMore(), for: .normal)
        }
    }
    
    func showError() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: R.string.localizable.error(),
                                          message: R.string.localizable.somethingWentWrong(),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: R.string.localizable.ok(), style: .default))
            self.present(alert, animated: true)
        }
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
