//
//  MenuAuthCell.swift
//  ForPDA
//
//  Created by Subvert on 08.05.2023.
//

import UIKit

final class MenuAuthCell: UITableViewCell {
    
    // MARK: - Views
    
    private(set) var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = R.image.avatarPlaceholder()
        // imageView.clipsToBounds = true
        // imageView.layer.cornerRadius = 22
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private(set) var titleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.guest()
        return label
    }()
    
    private(set) var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.authorize()
        label.font = .systemFont(ofSize: UIFont.labelFontSize - 3, weight: .light)
        return label
    }()
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = R.image.avatarPlaceholder()
        titleLabel.text = R.string.localizable.guest()
        subtitleLabel.text = R.string.localizable.authorize()
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    private func makeConstraints() {
        iconImageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.height.width.equalTo(44)
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView)
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(iconImageView)
            make.leading.equalTo(iconImageView.snp.trailing).offset(16)
        }
    }
}
