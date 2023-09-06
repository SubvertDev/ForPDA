//
//  CommentsVC.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit
import Factory
import SwiftSoup
import WebKit

protocol CommentsVCProtocol: AnyObject {
    func updateStarted()
    func updateFinished(_ state: Bool)
}

final class CommentsVC: CommentsViewController {
    
    // MARK: - Properties
    
    @Injected(\.parsingService) private var parsingService
    @Injected(\.settingsService) private var settingsService
    
    private var allComments: [Comment] = []
    private let article: Article
    private let document: String
    
    private var contentSizeObserver: NSKeyValueObservation!
    private var webView: WKWebView?
    private lazy var themeColor = settingsService.getAppBackgroundColor()
    
    weak var updateDelegate: CommentsVCProtocol?
            
    // MARK: - Lifecycle
    
    init(article: Article, document: String) {
        self.article = article
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(cellWithClass: ArticleCommentCell.self)
        getComments()
        setupWebView()
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupWebView() {
        if let webView = UIApplication.shared.windows.first?.viewWithTag(666) as? WKWebView {
            self.webView = webView
            webView.navigationDelegate = self
            let url = URL(string: article.url)!
            let request = URLRequest(url: url)
            
            if settingsService.getShowLikesInComments() {
                updateDelegate?.updateStarted()
                webView.load(request)
            }
        }
    }
        
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(changeDarkThemeBackgroundColor(_:)),
            name: .darkThemeBackgroundColorDidChange, object: nil
        )
    }
    
    @objc private func changeDarkThemeBackgroundColor(_ notification: Notification) {
        if let object = notification.object as? AppDarkThemeBackgroundColor {
            themeColor = object
        } else {
            themeColor = settingsService.getAppBackgroundColor()
        }
        tableView.reloadData()
    }
    
    // MARK: - Public Functions
    
    func updateAll() {
        guard let url = URL(string: article.url) else { return }
        let request = URLRequest(url: url)
        webView?.load(request)
    }
    
    // MARK: - Private Functions
    
    private func getComments() {
        allComments = parsingService.parseComments(from: document)
        
        currentlyDisplayed = allComments
        fullyExpanded = true
        
        tableView.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        
        contentSizeObserver = tableView.observe(\.contentSize, options: .new) { tableView, change in
            if let size = change.newValue {
                tableView.snp.updateConstraints { make in
                    make.height.equalTo(size.height)
                }
            }
        }
    }
    
    private func updateComments(with document: String) {
        _currentlyDisplayed.removeAll()
        DispatchQueue.global().async {
            let newComments = self.parsingService.parseComments(from: document)
            self.allComments = newComments
            self.currentlyDisplayed = self.allComments
            
            DispatchQueue.main.async {
                self.updateDelegate?.updateFinished(true)
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: - TableView DataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withClass: ArticleCommentCell.self, for: indexPath)
        if let comment = currentlyDisplayed[indexPath.row] as? Comment {
            cell.set(with: comment)
            cell.level = comment.level
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ArticleCommentCell {
            if currentlyDisplayed[indexPath.row].level % 2 == 0 {
                cell.myView.backgroundColor = themeColor == .dark ? R.color.nearBlack() : .systemBackground
            } else {
                cell.myView.backgroundColor = themeColor == .dark ? R.color.nearBlack() : .systemBackground
            }
            cell.indentationColor = .tertiarySystemGroupedBackground
            cell.commentMarginColor = .tertiarySystemGroupedBackground
        }
    }
}

// MARK: - WKNavigationDelegate

extension CommentsVC: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            webView.evaluateJavaScript("document.documentElement.outerHTML") { (doc, err) in
                if let document = doc as? String {
                    self.updateComments(with: document)
                } else {
                    print(err as Any)
                    self.updateDelegate?.updateFinished(false)
                }
            }
        }
    }
}
