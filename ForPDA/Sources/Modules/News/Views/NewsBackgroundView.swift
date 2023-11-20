//
//  NewsBackgroundView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.11.2023.
//

import UIKit
import SFSafeSymbols

final class NewsBackgroundView: UIView {
    
    convenience init(title: String, symbol: SFSymbol) {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(pointSize: 72)
        let image = UIImage(systemSymbol: symbol, withConfiguration: config)
        imageView.image = image
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = title
        label.numberOfLines = 0
        label.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical
        stack.spacing = 8
        
        self.init()
        
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-44)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
