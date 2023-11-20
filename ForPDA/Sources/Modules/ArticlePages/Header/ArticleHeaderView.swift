//
//  ArticleHeaderView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.11.2023.
//

import UIKit
import NukeExtensions

final class ArticleHeaderView: UIView {
    
    // MARK: - Views
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
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
    
    func configure(model: ArticleHeaderViewModel) {
        NukeExtensions.loadImage(with: model.imageUrl, into: imageView) { [weak self] result in
            guard let self else { return }
            // Adding overlay if opened from deeplink (test)
            if imageView.layer.sublayers?.count == nil {
                if (try? result.get()) != nil { imageView.addoverlay() }
            }
        }
        titleLabel.text = model.title
    }
}

// MARK: - Layout

extension ArticleHeaderView {
    
    private func addSubviews() {
        addSubview(imageView)
        addSubview(titleLabel)
    }
    
    private func makeConstraints() {
        imageView.snp.makeConstraints { make in
            make.width.equalTo(UIScreen.main.bounds.width)
            make.height.equalTo(UIScreen.main.bounds.width * 0.6)
            make.center.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(8)
        }
    }
}
