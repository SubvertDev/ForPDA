//
//  CommentsVC.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit

protocol CommentsVCProtocol: AnyObject {
    func updateComments(with comments: [Comment])
}

final class CommentsVC: CommentsViewController, UIGestureRecognizerDelegate {
    
    // MARK: - Properties
        
    private let presenter: CommentsPresenterProtocol
    
    private var allComments: [Comment] = []
    private lazy var themeColor = presenter.themeColor
    
    weak var collectionViewScrollDelegate: ArticleInnerScrollViewDelegate?
    var dragDirection: DragDirection = .up
    var oldContentOffset: CGPoint = .zero
    
    // MARK: - Init
    
    init(presenter: CommentsPresenterProtocol) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(cellWithClass: ArticleCommentCell.self)
        
        swipeToHide = false
        showOrHideOnTap = false
        fullyExpanded = true
        
        setupNotifications()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlCalled), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // MARK: - Public Functions
    
    func showComments(_ comments: [Comment]) {
        allComments = comments
        _currentlyDisplayed.removeAll()
        currentlyDisplayed = allComments
        tableView.reloadData()
        presenter.commentsHasUpdated()
        Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    // MARK: - Private Functions
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(changeNightModeBackgroundColor(_:)),
            name: .nightModeBackgroundColorDidChange, object: nil
        )
    }
    
    @objc private func changeNightModeBackgroundColor(_ notification: Notification) {
        if let object = notification.object as? AppNightModeBackgroundColor {
            themeColor = object
        } else {
            themeColor = presenter.themeColor
        }
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func refreshControlCalled() {
        presenter.updateComments()
    }
}

// MARK: - TableView DataSource

extension CommentsVC {
        
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

// MARK: - CommentsVCProtocol

extension CommentsVC: CommentsVCProtocol {
    
    func updateComments(with comments: [Comment]) {
        Task { @MainActor in
            showComments(comments)
        }
    }
}
