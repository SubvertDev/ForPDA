//
//  CommentsVC.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit
import SwiftSoup
import WebKit
import SafariServices

final class CommentsVC: CommentsViewController {
    
    private var webView: WKWebView!
    
    private var allComments: [Comment] = []
    private var parsed: Document!
    var article: Article!
            
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    // MARK: - Setup
    private func setup() {
        webView = UIApplication.shared.windows.first!.viewWithTag(666)! as? WKWebView
        webView.navigationDelegate = self
        // print(article.url)
        let url = URL(string: article.url)!
        let request = URLRequest(url: url)
        webView.load(request)
        
        tableView.register(ArticleCommentCell.self, forCellReuseIdentifier: ArticleCommentCell.reuseIdentifier)
    }
    
    // MARK: - Functions
    
    private func getComments() {
        let commentList = try! parsed.select("ul[class=comment-list level-0").select("li[data-author-id]")
        allComments += recursed(commentList: commentList, level: 0)
        
        currentlyDisplayed = allComments
        fullyExpanded = true
        tableView.reloadData()
        
        tableView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
        
        tableView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
    }
    
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
    
    private func recursed(commentList: Elements, level: Int) -> [Comment] {
        
        var allComments = [Comment]()
        let newComments = Elements()
        
        for comments in commentList {
            let parentElement = comments.parent()
            let isLeveled = try! parentElement?.iS("ul[class=comment-list level-\(level)]") ?? true
            if isLeveled { newComments.add(comments) }
        }
        
        for comments in newComments {
            let replies = try! comments.select("[class*=comment-list]").select("li[data-author-id]")
            if replies.count > 0 {
                let nextLevelList = try! comments.select("[class*=comment-list level-\(level + 1)]").select("li[data-author-id]")
                let replies = recursed(commentList: nextLevelList, level: level + 1)
                allComments.append(getCommentFromElement(comments, replies: replies, level: level))
            } else {
                if !comments.hasAttr("style") {
                    allComments.append(getCommentFromElement(comments, level: level))
                }
            }
        }
        
        return allComments
    }
    
    private func getCommentFromElement(_ element: Element, replies: [AbstractComment] = [], level: Int) -> Comment {
        try! element.select("ul[class*=comment-list]").remove()
        let commentType = try! element.select("div[id]").attr("class")
        guard commentType != "deleted" else {
            return Comment(author: "Неизвестно", text: "(Комментарий удален)", date: "", likes: 0, replies: replies, level: level)
        }
        let author = try! element.select("[class=nickname]").first()?.text() ?? "Error"
        let text = try! element.select("[class=content]").first()?.text() ?? "Error"
        let date = try! element.select("[class=date").first()?.text() ?? "0.0.0"
        
        let likes: Int
        if let likesAmount = try! element.select("[class=num]").first()?.text() {
            likes = Int(likesAmount) ?? 0
        } else {
            likes = 0
        }
        
        return Comment(author: author, text: text, date: date, likes: likes, replies: replies, level: level)
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

extension CommentsVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("FINISHED LOADING COMMENTS")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // waiting to get likes loaded
            webView.evaluateJavaScript("document.documentElement.outerHTML") { (doc, err) in
                if let document = doc as? String {
                    self.parsed = try! SwiftSoup.parse(document)
                    self.getComments()
                    
                } else {
                    print(err!)
                }
            }
        }
    }
}
