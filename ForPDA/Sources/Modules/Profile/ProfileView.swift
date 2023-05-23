//
//  ProfileView.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//

import UIKit

protocol ProfileViewDelegate: AnyObject {
    func logoutButtonTapped()
}

final class ProfileView: UIView {
    
    // MARK: - Views
    
    private(set) var profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private(set) var nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    
    private(set) var errorMessageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
    }()
    
    private(set) lazy var logoutButton: LoadingButton = {
        let button = LoadingButton(type: .system)
        button.setTitle(R.string.localizable.signOut(), for: .normal)
        button.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    weak var delegate: ProfileViewDelegate?
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc private func logoutButtonTapped() {
        delegate?.logoutButtonTapped()
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        [profileImageView,
         nameLabel,
         errorMessageLabel,
         logoutButton
        ].forEach { addSubview($0) }
    }
    
    private func makeConstraints() {
        profileImageView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(150)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(16)
            make.centerX.equalTo(profileImageView)
        }
        
        errorMessageLabel.snp.makeConstraints { make in
            make.bottom.equalTo(logoutButton.snp.top).inset(32)
            make.centerX.equalToSuperview()
        }
        
        logoutButton.snp.makeConstraints { make in
            make.bottom.equalTo(safeAreaLayoutGuide).inset(32)
            make.centerX.equalToSuperview()
        }
    }
}
