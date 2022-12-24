//
//  CommentsVC.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit
import SwiftSoup
// import WebKit
import SafariServices

final class CommentsVC: CommentsViewController {
    
    // private var webView: WKWebView!
    
    private var allComments: [Comment] = []
    var articleDocument: Document!
    var article: Article!
            
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ArticleCommentCell.self, forCellReuseIdentifier: ArticleCommentCell.reuseIdentifier)
        getComments()
        setupWebView()
    }
    
    // MARK: - Setup
    private func setupWebView() {
//        webView = UIApplication.shared.windows.first!.viewWithTag(666)! as? WKWebView
//        webView.navigationDelegate = self
//        let url = URL(string: article.url)!
//        let request = URLRequest(url: url)
//        webView.load(request)
    }
    
    // MARK: - Functions
    
    private func getComments() {
        allComments = DocumentParser.shared.parseComments(from: articleDocument)
        
        currentlyDisplayed = allComments
        fullyExpanded = true
        tableView.reloadData()
        
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        tableView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
    }
    
    private func updateComments(with document: Document) {
        _currentlyDisplayed.removeAll()
        allComments = DocumentParser.shared.parseComments(from: document)
        currentlyDisplayed = allComments
        tableView.reloadData()
    }
    
    // MARK: - Observers
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "contentSize" {
            if let newvalue = change?[.newKey] {
                let newsize = newvalue as! CGSize
                // tableViewHeightConstraint.constant = newsize.height
                tableView.snp.updateConstraints { make in
                    make.height.equalTo(newsize.height)
                }
            }
        }
    }
    
    // MARK: - TableView DataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCommentCell.reuseIdentifier,
                                                 for: indexPath) as! ArticleCommentCell
        let comment = currentlyDisplayed[indexPath.row] as! Comment
        cell.set(with: comment)
        cell.level = comment.level
        return cell
    }
    
}

//extension CommentsVC: WKNavigationDelegate {
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        print("FINISHED LOADING COMMENTS")
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // waiting to get likes loaded
//            webView.evaluateJavaScript("document.documentElement.outerHTML") { (doc, err) in
//                if let document = doc as? String {
//                    let document = try! SwiftSoup.parse(document)
//                    self.updateComments(with: document)
//                } else {
//                    print(err!)
//                }
//            }
//        }
//    }
//}
