//
//  ArticleCommentsFooterView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.11.2023.
//

import UIKit

protocol ArticleCommentsFooterViewDelegate: AnyObject {
    func footerTapped()
}

final class ArticleCommentsFooterView: UICollectionReusableView {
    
    // MARK: - Views
    
    private lazy var labelsStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            commentsLabel, swipeToShowCommentsLabel
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fill
        return stack
    }()
    
    private let commentsLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.comments(0)
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private let swipeToShowCommentsLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.swipeLeftToShowComments()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    // MARK: - Properties
    
    weak var delegate: ArticleCommentsFooterViewDelegate?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(footerTapped))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Functions
    
    func configure(model: ArticleCommentsFooterViewModel) {
        commentsLabel.text = R.string.localizable.comments(model.amountOfComments)
    }
    
    // MARK: - Tap Action
    
    @objc private func footerTapped() {
        delegate?.footerTapped()
    }
}

// MARK: - Layout

extension ArticleCommentsFooterView {
    
    private func addSubviews() {
        addSubview(labelsStackView)
    }
    
    private func makeConstraints() {
        labelsStackView.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(16)
            make.horizontalEdges.equalToSuperview().inset(12)
        }
    }
}
