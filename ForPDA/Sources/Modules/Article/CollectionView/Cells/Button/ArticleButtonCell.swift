//
//  ArticleButtonCell.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit
import Factory

final class ArticleButtonCell: UICollectionViewCell {
    
    // MARK: - Views

    private lazy var button: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        // (todo) (important) Make UIButton with Configuartion
        // button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        return button
    }()
    
    // MARK: - Properties
    
    @LazyInjected(\.analyticsService) private var analytics
    private var url: URL?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Functions
    
    func configure(model: ArticleButtonCellModel) {
        if model.title.isEmpty {
            fatalError()
        }
        button.setTitle(model.title, for: .normal)
        button.titleLabel?.textAlignment = .center
        url = model.url
    }
    
    // MARK: - Actions
    
    @objc private func buttonTapped() {
        if let url, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            analytics.event(Event.Article.articleButtonClicked.rawValue)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        url = nil
    }
    
}

// MARK: - Layout

extension ArticleButtonCell {
    
    private func addSubviews() {
        contentView.addSubview(button)
    }
    
    private func makeConstraints() {
        button.snp.makeConstraints { make in
            make.verticalEdges.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(16)
            make.right.lessThanOrEqualToSuperview().inset(16)
        }
    }
    
}
