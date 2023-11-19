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
import RouteComposer
import Sentry

protocol NewsVCProtocol: AnyObject {
    func articlesUpdated()
    func showCaptchaVerification()
    func showError()
}

final class NewsVC: PDAViewControllerWithView<NewsView> {
    
    // MARK: - Properties
    
    @Injected(\.analyticsService) private var analytics
    
    private let presenter: NewsPresenterProtocol

    // MARK: - Lifecycle
    
    init(presenter: NewsPresenter) {
        self.presenter = presenter
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegates()
        configureNavBar()
        
        Task {
            await presenter.loadArticles()
        }
//        Task { @MainActor in
//            try await Task.sleep(nanoseconds: 0_500_000_000)
//            showCaptchaVerification()
//        }
    }
    
    // MARK: - Configuration
    
    private func setDelegates() {
        myView.delegate = self
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
    }
    
    private func configureNavBar() {
        let button = UIBarButtonItem(
            image: UIImage(systemSymbol: .listDash)
                .withTintColor(.label, renderingMode: .alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(menuButtonTapped)
        )
        navigationItem.rightBarButtonItem = button
    }
    
    @objc private func menuButtonTapped() {
        presenter.menuButtonTapped()
        analytics.event(Event.News.menuOpen.rawValue)
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
        myView.tableView.backgroundView = nil
        myView.tableView.reloadData()
        myView.refreshButton.isHidden = false
        myView.refreshButton.setTitle(R.string.localizable.loadMore(), for: .normal)
        myView.loadingIndicator.isHidden = true
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            myView.refreshControl.endRefreshing()
        }
    }
    
    func showCaptchaVerification() {
        analytics.event(Event.News.vpnWarningShown.rawValue)

        let alert = UIAlertController(
            title: R.string.localizable.whoops(),
            message: R.string.localizable.vpnWarning(),
            preferredStyle: .alert
        )
        
        let okAction = UIAlertAction(title: R.string.localizable.vpnTurnOff(), style: .cancel) { [weak self] _ in
            guard let self else { return }
            analytics.event(Event.News.vpnDisableOptionChosen.rawValue)
            UIApplication.shared.open(URL(string: "com.apple.preferences:")!)
            showVPNBackgroundView()
        }
        let captchaAction = UIAlertAction(title: R.string.localizable.vpnShowCaptcha(), style: .default) { [weak self] _ in
            guard let self else { return }
            analytics.event(Event.News.vpnCaptchaOptionChosen.rawValue)
            let request = URLRequest(url: URL.fourpda)
            let webVC = WebVC(request: request) { [weak self] in
                guard let self else { return }
                Task { await self.presenter.loadArticles() }
                showAlert(title: R.string.localizable.warning(), message: R.string.localizable.vpnFlsIncompatible())
            }
            webVC.modalPresentationStyle = .overCurrentContext
            present(webVC, animated: true)
        }
        
        alert.addAction(okAction)
        alert.addAction(captchaAction)
        
        present(alert, animated: true)
    }
    
    func showError() {
        let backgroundView = NewsBackgroundView(
            title: R.string.localizable.whoops() + " " + R.string.localizable.somethingWentWrong(),
            symbol: .questionmark
        )
        myView.tableView.backgroundView = backgroundView
        myView.loadingIndicator.isHidden = true
        myView.refreshControl.endRefreshing()   
    }
    
    private func showVPNBackgroundView() {
        let backgroundView = NewsBackgroundView(
            title: R.string.localizable.vpnWarningBackground(),
            symbol: .wifiExclamationmark
        )
        myView.tableView.backgroundView = backgroundView
        myView.refreshControl.endRefreshing()
        myView.loadingIndicator.isHidden = true
    }
}

// MARK: - NewsView Delegate

extension NewsVC: NewsViewDelegate {
    
    func refreshButtonTapped() {
        myView.refreshButton.setTitle(R.string.localizable.loadingDots(), for: .normal)
        Task {
            await presenter.loadArticles()
        }
    }
    
    func refreshControlCalled() {
        Task {
            await presenter.refreshArticles()
        }
    }
}

// MARK: - TableView Delegate

extension NewsVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        analytics.event(Event.News.articleOpen.rawValue)
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
            SwiftMessages.showDefault(title: R.string.localizable.copied(), body: "")
            analytics.event(Event.News.newsLinkCopied.rawValue)
        }
    }
    
    private func shareAction(article: Article) -> UIAction {
        UIAction.make(title: R.string.localizable.shareLink(), symbol: .arrowTurnUpRight) { [unowned self] _ in
            let activity = UIActivityViewController(activityItems: [article.url], applicationActivities: nil)
            present(activity, animated: true)
            analytics.event(Event.News.newsLinkShared.rawValue)
        }
    }
    
    private func reportAction(article: Article) -> UIAction {
        UIAction.make(title: R.string.localizable.somethingWrongWithArticle(), symbol: .questionmarkCircle) { [unowned self] _ in
            SwiftMessages.showDefault(title: R.string.localizable.thanks(), body: R.string.localizable.willFixSoon())
            SentrySDK.capture(error: SentryCustomError.badArticle(url: article.url))
            analytics.event(Event.News.newsReport.rawValue)
        }
    }
}
