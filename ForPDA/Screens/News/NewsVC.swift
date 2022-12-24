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
    
    private var viewModel: NewsVM!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: myView.tableView)
            if let indexPath = myView.tableView.indexPathForRow(at: touchPoint) {
                UIPasteboard.general.string = articles[indexPath.row].url

                SwiftMessages.show {
                    let view = MessageView.viewFromNib(layout: .centeredView)
                    view.configureTheme(.success)
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

// MARK: - TableView Delegate & Data

extension NewsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.reuseIdentifier, for: indexPath) as! ArticleCell
        cell.set(article: articles[indexPath.row])
        return cell
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
        let vc = ArticleVC(article: articles[indexPath.row])
//        let vc = CommentsVC()
//        vc.article = articles[indexPath.row]
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.pushViewController(vc, animated: false)
    }
}
