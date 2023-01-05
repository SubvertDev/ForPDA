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
        
        setupLongPressGesture()
        
        viewModel = NewsVM(view: self)
        viewModel.loadArticles()
    }
    
    // MARK: - Long Press Logic
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        // longPressGesture.delegate = self
        myView.addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: myView.tableView)
            if let indexPath = myView.tableView.indexPathForRow(at: touchPoint) {
                UIPasteboard.general.string = articles[indexPath.row].url

                SwiftMessages.show {
                    let view = MessageView.viewFromNib(layout: .centeredView)
                    view.configureTheme(backgroundColor: .systemBlue, foregroundColor: .white)
                    view.configureDropShadow()
                    view.configureContent(title: "Скопировано", body: self.articles[indexPath.row].url)
                    (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
                    view.button?.isHidden = true
                    return view
                }
            }
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
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
       if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0 {
          navigationController?.setNavigationBarHidden(true, animated: true)
       } else {
          navigationController?.setNavigationBarHidden(false, animated: true)
       }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let articleVC = ArticleVC(article: articles[indexPath.row])
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.pushViewController(articleVC, animated: false)
    }
}
