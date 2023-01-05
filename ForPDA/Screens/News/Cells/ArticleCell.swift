//
//  ArticleCell.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Nuke
import NukeExtensions

final class ArticleCell: UITableViewCell {
    
    static let reuseIdentifier = "ArticleCell"
    
    // MARK: - Views
    
    private let articleImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let reviewLabel: PDAPaddingLabel = {
        let label = PDAPaddingLabel()
        label.text = "Обзор"
        label.textColor = .systemBackground
        label.textEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        label.backgroundColor = .systemPurple.withAlphaComponent(0.8)
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.clipsToBounds = true
        label.layer.cornerRadius = 10
        label.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        label.isHidden = true
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Заголовок"
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Описание"
        label.numberOfLines = 3
        label.font = UIFont.systemFont(ofSize: 15, weight: .light)
        return label
    }()
    
    private let pdaImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "4.circle.fill")
        imageView.tintColor = .systemGray
        return imageView
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.text = "Автор"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemGray
        return label
    }()
    
    private let commentsImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "message")
        imageView.tintColor = .systemGray
        return imageView
    }()
    
    private let commentsLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemGray
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.text = "00.00.0000"
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        label.textColor = .systemGray
        return label
    }()
    
    // MARK: - Cell Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        separatorInset = .zero
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(article: Article) {
        titleLabel.text = article.title
        descriptionLabel.text = article.description
        authorLabel.text = article.author
        commentsLabel.text = article.commentAmount
        dateLabel.text = article.date
        reviewLabel.isHidden = !article.isReview
        
        if let url = URL(string: article.imageUrl) {
            NukeExtensions.loadImage(with: url, into: articleImage)
        }
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        contentView.addSubview(articleImage)
        contentView.addSubview(reviewLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        // contentView.addSubview(pdaImage)
        contentView.addSubview(authorLabel)
        contentView.addSubview(commentsImage)
        contentView.addSubview(commentsLabel)
        contentView.addSubview(dateLabel)
    }
    
    private func makeConstraints() {
        articleImage.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(articleImage.snp.width).multipliedBy(0.5)
        }
        
        reviewLabel.snp.makeConstraints { make in
            make.top.equalTo(articleImage).inset(16)
            make.leading.equalTo(articleImage)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(articleImage.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // pdaImage.snp.makeConstraints { make in
        //     make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
        //     make.bottom.equalToSuperview().inset(8)
        //     make.leading.equalToSuperview().inset(20)
        //     make.width.equalTo(pdaImage.snp.height)
        //     make.height.equalTo(28)
        // }
        
        authorLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(12)
        }
        
        commentsImage.snp.makeConstraints { make in
            make.trailing.equalTo(commentsLabel.snp.leading).offset(-4)
            make.centerY.equalTo(authorLabel)
        }
        
        commentsLabel.snp.makeConstraints { make in
            make.trailing.equalTo(dateLabel.snp.leading).offset(-16)
            make.centerY.equalTo(authorLabel)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.centerY.equalTo(authorLabel)
        }
    }
    
}
