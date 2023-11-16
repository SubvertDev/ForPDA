//
//  ArticleCommentsCell.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 11.11.2023.
//

import UIKit

protocol ArticleCommentsCellDelegate: AnyObject {
    func updateLayout()
}

final class ArticleCommentsCell: UICollectionViewCell {
    
    // MARK: - Views

    private let commentsVC = CommentsVC()
    
    // MARK: - Properties
    
    weak var delegate: ArticleCommentsCellDelegate?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
        
        commentsVC.updateDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Functions
    
    func configure(model: ArticleCommentsCellModel) {
        guard model.comments.count > 0 else { return }
        commentsVC.getComments(model.comments)
    }
    
}

// MARK: - Comments Delegate

extension ArticleCommentsCell: CommentsVCProtocol {
    
    func tableViewHeightChanged(_ height: CGFloat) {
        commentsVC.view.snp.updateConstraints { [weak self] make in
            guard let self else { return }
            make.height.equalTo(commentsVC.tableView.contentSize.height).priority(999)
        }
        delegate?.updateLayout()
    }
    
    func updateFinished(_ state: Bool) {
        print(#function)
    }
    
}

// MARK: - Layout

extension ArticleCommentsCell {
    
    private func addSubviews() {
        contentView.addSubview(commentsVC.view)
    }
    
    private func makeConstraints() {
        commentsVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(0).priority(999)
        }
    }
    
}
