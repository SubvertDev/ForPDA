//
//  ArticleBulletListCell.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit

final class ArticleBulletListCell: UICollectionViewCell {
    
    // MARK: - Views

    private let mainStackView: UIStackView = {
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill
        mainStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: 12, bottom: 0, trailing: 12
        )
        return mainStackView
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
    
    func configure(model: ArticleBulletListCellModel) {
        for bullet in model.elements {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .fill
            
            let leftLabel = PDABulletLabel(text: bullet.title, type: .left)
            leftLabel.snp.makeConstraints { make in
                make.width.equalTo(UIScreen.main.bounds.width / 3)
            }
            stackView.addArrangedSubview(leftLabel)
            
            var text = ""
            for desc in bullet.description { text += desc }
            text.removeLast()
            let rightLabel = PDABulletLabel(text: text, type: .right)
            stackView.addArrangedSubview(rightLabel)
            
            mainStackView.addArrangedSubview(stackView)
        }
    }
    
}

// MARK: - Layout

extension ArticleBulletListCell {
    
    private func addSubviews() {
        contentView.addSubview(mainStackView)
    }
    
    private func makeConstraints() {
        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}
