//
//  MenuSettingsCell.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit

final class MenuSettingsCell: UITableViewCell {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: UIFont.labelFontSize - 1, weight: .medium)
        label.textColor = label.textColor.withAlphaComponent(0.8)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func set(with model: MenuOption) {
        if let icon = model.icon {
            let color: UIColor = icon == .heartFill ? .systemRed : .systemGray
            iconImageView.image = UIImage(systemSymbol: icon).withTintColor(color, renderingMode: .alwaysOriginal)
        } else if let image = model.image {
            iconImageView.image = image
        }
        titleLabel.text = model.title
    }
    
    private func addSubviews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
    }
    
    private func makeConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(11)
            make.height.equalTo(24)
            make.width.equalTo(60)
            make.leading.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalTo(iconImageView.snp.trailing).offset(4)
        }
    }
    
}
