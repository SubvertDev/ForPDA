//
//  PDAResizingImageViewWithText.swift
//  ForPDA
//
//  Created by Subvert on 06.01.2023.
//

import UIKit

final class PDAResizingImageViewWithText: UIStackView {
    
    private(set) var imageView = PDAResizingImageView()
    
    private let textLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemGray
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    init(_ text: String) {
        super.init(frame: .zero)
        
        distribution = .fillProportionally
        axis = .vertical
        spacing = 4
        
        textLabel.text = text
        
        addArrangedSubview(imageView)
        addArrangedSubview(textLabel)
        
        textLabel.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
