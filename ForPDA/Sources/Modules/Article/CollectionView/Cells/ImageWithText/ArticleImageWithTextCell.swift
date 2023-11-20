//
//  ArticleImageWithTextCell.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit
import NukeExtensions

final class ArticleImageWithTextCell: UICollectionViewCell {
    
    // MARK: - Views

    private let imageViewWithText = PDAResizingImageViewWithText("")
    
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
    
    func configure(model: ArticleImageWithTextCellModel) {
        let ratio = CGFloat(model.height) / CGFloat(model.width)
        let height = Int(ratio * UIScreen.main.bounds.width)
        imageViewWithText.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(height).priority(999)
        }
        
        imageViewWithText.textLabel.text = model.description
        NukeExtensions.loadImage(with: model.imageUrl, into: imageViewWithText.imageView) { _ in }
    }
    
}

// MARK: - Layout

extension ArticleImageWithTextCell {
    
    private func addSubviews() {
        contentView.addSubview(imageViewWithText)
    }
    
    private func makeConstraints() {
        imageViewWithText.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}
