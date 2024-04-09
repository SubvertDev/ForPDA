//
//  ArticleBackgroundView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 20.11.2023.
//

import UIKit

final class ArticleBackgroundView: UIView {
    
    convenience init(title: String) {
        let progress = ProgressViewKit(colors: [.label], lineWidth: 4)
        progress.isAnimating = true
        
        let label = UILabel()
        label.text = title
        label.numberOfLines = 0
        label.textAlignment = .center
        
        self.init()
        
        addSubview(progress)
        addSubview(label)
        
        progress.snp.makeConstraints { make in
            make.size.equalTo(44)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-44)
        }
        
        label.snp.makeConstraints { make in
            make.top.equalTo(progress.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
