//
//  ArticleCommentCell.swift
//  ForPDA
//
//  Created by Subvert on 05.12.2022.
//

import UIKit

final class ArticleCommentCell: CommentCell {
    
    static let reuseIdentifier = "ArticleCommentCell"
    
    var myView: ArticleCommentView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        let view = ArticleCommentView()
        view.backgroundColor = .systemBackground
        myView = view
        self.commentViewContent = view
        
        rootCommentMarginColor = .systemBlue
        rootCommentMargin = 1
        
        indentationUnit = 12
        // indentationColor = .systemRed
        indentationIndicatorThickness = 0
        
        commentMargin = 8
        commentMarginColor = .systemBackground
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(with comment: Comment) {
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
            myView.backgroundColor = .systemGroupedBackground
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

final class ArticleCommentView: UIView {
    
    let authorLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let textLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    
    let dateLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    let likesLabel: UILabel = {
        let label = UILabel()
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubviews() {
        addSubview(authorLabel)
        addSubview(textLabel)
        addSubview(dateLabel)
        addSubview(likesLabel)
    }
    
    private func makeConstraints() {
        authorLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(4)
        }
        
        textLabel.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(4)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(authorLabel)
            make.trailing.equalToSuperview().offset(-4)
        }
        
        likesLabel.snp.makeConstraints { make in
            make.centerY.equalTo(authorLabel)
            make.trailing.equalTo(dateLabel.snp.leading).offset(-8)
        }
    }
    
}
