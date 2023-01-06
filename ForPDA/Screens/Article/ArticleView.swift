//
//  ArticleView.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Nuke

final class ArticleView: UIView {
    
    // MARK: - Views
    
    let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    let articleImage: PDAResizingImageView = {
        let imageView = PDAResizingImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.addoverlay()
        return imageView
    }()
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 25, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 2.0
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = .zero
        label.layer.masksToBounds = false
        return label
    }()
    
    let hideView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()
    
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
    }()
    
    let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .label
        return view
    }()
    
    let commentsLabel: UILabel = {
        let label = UILabel()
        label.text = "Комментарии:"
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    let commentsContainer = UIView()
    
    // MARK: - View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func removeComments() {
        separator.removeFromSuperview()
        commentsLabel.removeFromSuperview()
        commentsContainer.removeFromSuperview()
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(articleImage)
        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        contentView.addSubview(hideView)
        contentView.addSubview(separator)
        contentView.addSubview(commentsLabel)
        contentView.addSubview(commentsContainer)
    }
    
    private func makeConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(self).priority(700)
            make.width.equalTo(self)
        }
        
        articleImage.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(articleImage.snp.width).multipliedBy(0.6)
            make.width.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(articleImage).inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(articleImage.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        hideView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(stackView)
        }
        
        separator.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        commentsLabel.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(12)
        }
        
        commentsContainer.snp.makeConstraints { make in
            make.top.equalTo(commentsLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
