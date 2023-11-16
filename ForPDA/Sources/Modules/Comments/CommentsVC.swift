//
//  CommentsVC.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit
import Factory

protocol CommentsVCProtocol: AnyObject {
    func tableViewHeightChanged(_ height: CGFloat)
}

final class CommentsVC: CommentsViewController {
    
    // MARK: - Properties
    
    @Injected(\.settingsService) private var settings
    
    private var allComments: [Comment] = []
    private var previousHeight: CGFloat = 0
    private var contentSizeObserver: NSKeyValueObservation!
    private var throttleTimer: Timer?
    private var gotComments = false
    private lazy var themeColor = settings.getAppBackgroundColor()
    
    weak var updateDelegate: CommentsVCProtocol?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(cellWithClass: ArticleCommentCell.self)
        
        showOrHideOnTap = false
        
        setupNotifications()
        
        contentSizeObserver = tableView.observe(\.contentSize, options: .new) { [weak self] tableView, change in
            guard let self else { return }
            if let size = change.newValue, size.height != 0, size.height > previousHeight {
                previousHeight = size.height
                startThrottler()
            }
        }
    }
    
    // MARK: - Public Functions
    
    func getComments(_ comments: [Comment]) {
        guard !gotComments else { return }
        gotComments = true
        
        allComments = comments
        currentlyDisplayed = allComments
        fullyExpanded = true
        tableView.reloadData()
        
        // Initial calculation based on smallest cell to minimize amount of size guessing
        let commentsAmount = Comment.countTotalComments(comments)
        let initialHeight = CGFloat(commentsAmount * 57)
        previousHeight = initialHeight
        tableView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: initialHeight)
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
            themeColor = settings.getAppBackgroundColor()
        }
        tableView.reloadData()
    }
    
    private func startThrottler() {
        let throttleTime = settings.getShowLikesInComments() ? 0.5 : 0.1
        throttleTimer?.invalidate()
        throttleTimer = nil
        throttleTimer = Timer.scheduledTimer(withTimeInterval: throttleTime, repeats: false) { [weak self] _ in
            guard let self else { return }
            updateDelegate?.tableViewHeightChanged(previousHeight)
        }
        RunLoop.main.add(throttleTimer!, forMode: .common)
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
