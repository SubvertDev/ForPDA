//
//  SearchView.swift
//  ForPDA
//
//  Created by Subvert on 14.05.2023.
//

import UIKit

final class SearchView: UIView {
    
    private let label: UILabel = {
        let label = UILabel()
        label.text = "Находится в разработке"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
