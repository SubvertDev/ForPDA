//
//  PDAResizingImageViewWithText.swift
//  ForPDA
//
//  Created by Subvert on 06.01.2023.
//

import UIKit

final class PDAResizingImageViewWithText: UIView {
    
    let imageView = PDAResizingImageView()
    
    let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    init(_ text: String) {
        super.init(frame: .zero)
        setupView()
        textLabel.text = text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        addSubview(imageView)
        addSubview(textLabel)
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        textLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(imageView.snp.bottom).offset(4)
            make.bottom.equalToSuperview()
        }
    }
}
