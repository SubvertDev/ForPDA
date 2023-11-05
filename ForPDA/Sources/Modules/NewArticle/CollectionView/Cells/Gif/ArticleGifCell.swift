//
//  ArticleGifCell.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit

final class ArticleGifCell: UICollectionViewCell {
    
    // MARK: - Views

    private let imageView = PDAResizingImageView()
    
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
    
    func configure(model: ArticleGifCellModel) {
        let ratio = CGFloat(model.height) / CGFloat(model.width)
        let height = Int(ratio * UIScreen.main.bounds.width)
        imageView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(height)
        }
        imageView.setGifFromURL(model.gifUrl)
    }
    
}

// MARK: - Layout

extension ArticleGifCell {
    
    private func addSubviews() {
        contentView.addSubview(imageView)
    }
    
    private func makeConstraints() {
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}
