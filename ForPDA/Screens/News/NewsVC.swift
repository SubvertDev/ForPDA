//
//  NewsVC.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import SwiftSoup
import Nuke
import SwiftMessages

final class NewsVC: PDAViewController<NewsView> {
    
    // MARK: - Properties
    
    private let host = "https://4pda.to/"
    var articles = [Article]()
    var page = 1
    
    private var viewModel: NewsVM!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myView.delegate = self
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
        
        viewModel = NewsVM(view: self)
        viewModel.loadArticles()
    }
    
    // MARK: - Actions
    
    private func copyLinkTapped(at row: Int) {
        UIPasteboard.general.string = articles[row].url

        SwiftMessages.show {
            let view = MessageView.viewFromNib(layout: .centeredView)
            view.configureTheme(backgroundColor: .systemBlue, foregroundColor: .white)
            view.configureDropShadow()
            view.configureContent(title: "Скопировано", body: "")
            (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            view.button?.isHidden = true
            return view
        }
    }
    
    @objc private func reportBrokenArticleTapped() {
        SwiftMessages.show {
            let view = MessageView.viewFromNib(layout: .centeredView)
            view.configureTheme(backgroundColor: .systemBlue, foregroundColor: .white)
            view.configureDropShadow()
            view.configureContent(title: "Спасибо!", body: "Починим в ближайшее время :)")
            (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            view.button?.isHidden = true
            return view
        }
    }
}

// MARK: - View Delegate

extension NewsVC: NewsViewDelegate {
    func refreshButtonTapped() {
        page += 1
        myView.refreshButton.setTitle("Загружаю...", for: .normal)
        viewModel.loadArticles(atPage: page)
    }
    
    func refreshControlCalled() {
        viewModel.refreshArticles()
    }
}

// MARK: - TableView Delegate & Data

extension NewsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ArticleCell.self, for: indexPath)
        cell.set(article: articles[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 350
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let clipboardImage = UIImage(systemName: "clipboard")
            let copyLinkItem = UIAction(title: "Скопировать ссылку", image: clipboardImage) { [unowned self] _ in
                self.copyLinkTapped(at: indexPath.row)
                AnalyticsHelper.copyArticleLink(articles[indexPath.row].url)
            }
            
            let shareImage = UIImage(systemName: "arrowshape.turn.up.right")
            let shareLinkItem = UIAction(title: "Поделиться ссылкой", image: shareImage) { [unowned self] _ in
                let items = [self.articles[indexPath.row].url]
                let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
                self.present(activity, animated: true)
                AnalyticsHelper.shareArticleLink(articles[indexPath.row].url)
            }
            
            let questionImage = UIImage(systemName: "questionmark.circle")
            let brokenArticleItem = UIAction(title: "Проблемы со статьей?", image: questionImage) { [unowned self] _ in
                self.reportBrokenArticleTapped()
                AnalyticsHelper.reportBrokenArticle(articles[indexPath.row].url)
            }
            
            return UIMenu(title: "", options: .displayInline, children: [copyLinkItem, shareLinkItem, brokenArticleItem])
        }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
       if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0 {
          navigationController?.setNavigationBarHidden(true, animated: true)
       } else {
          navigationController?.setNavigationBarHidden(false, animated: true)
       }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let article = articles[indexPath.row]
        let articleVC = ArticleVC(article: articles[indexPath.row])
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.pushViewController(articleVC, animated: true)
        
        AnalyticsHelper.openArticleEvent(article.url)
    }
}
