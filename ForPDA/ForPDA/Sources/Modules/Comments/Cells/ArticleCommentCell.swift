//
//  ArticleCommentCell.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit
import NukeExtensions

final class ArticleCommentCell: CommentCell {
    
    var myView: ArticleCommentView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let view = ArticleCommentView()
        view.backgroundColor = .systemBackground
        myView = view
        self.commentViewContent = view
        
        rootCommentMarginColor = .tertiarySystemGroupedBackground
        rootCommentMargin = 12
        
        indentationUnit = 12
        // indentationColor = .systemRed
        indentationIndicatorThickness = 0
        
        commentMargin = 4
        commentMarginColor = .tertiarySystemBackground
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(with comment: Comment) {
        NukeExtensions.loadImage(with: comment.avatarUrl, into: myView.avatarImageView) { _ in }
        myView.authorLabel.text = comment.author
        myView.textLabel.text = comment.text
        myView.dateLabel.text = comment.date
        if comment.likes > 0 {
            myView.likesLabel.text = String(comment.likes)
        }
        
        if comment.level % 2 == 0 {
            myView.backgroundColor = .systemBackground
            indentationColor = .systemBackground
        } else {
            myView.backgroundColor = .secondarySystemBackground
            indentationColor = .systemBackground
        }
    }
    
    override func prepareForReuse() {
        myView.authorLabel.text = ""
        myView.textLabel.text = ""
        myView.dateLabel.text = ""
        myView.likesLabel.text = ""
    }
}
