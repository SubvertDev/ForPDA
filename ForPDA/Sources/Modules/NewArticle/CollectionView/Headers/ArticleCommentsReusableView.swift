//
//  ArticleCommentsReusableView.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 11.11.2023.
//

import UIKit

protocol ArticleCommentsReusableViewOutputDelegate: AnyObject {
    func updateCommentsButtonTapped()
}

protocol ArticleCommentsReusableViewInputDelegate: AnyObject {
    func stopAnimating()
}

struct ArticleCommentsReusableViewModel {
    let amount: Int
}

final class ArticleCommentsReusableView: UICollectionReusableView {
    
    // MARK: - Views
    
    private let commentsLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.comments(0)
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private lazy var updateCommentsButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemSymbol: .arrowTriangle2Circlepath, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(updateCommentsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    weak var delegate: ArticleCommentsReusableViewOutputDelegate?
    
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
    
    func configure(model: ArticleCommentsReusableViewModel) {        
        commentsLabel.text = R.string.localizable.comments(model.amount)
    }
    
    // MARK: - Actions
    
    @objc private func updateCommentsButtonTapped() {
        if !updateCommentsButton.isButtonAnimatingNow {
            delegate?.updateCommentsButtonTapped()
            UIView.animate(withDuration: 0.5, delay: 0, options: [.repeat, .allowUserInteraction]) {
                self.updateCommentsButton.transform = self.updateCommentsButton.transform.rotated(by: .pi)
            }
        }
    }
    
}

// MARK: - ArticleCommentsReusableViewInputDelegate

extension ArticleCommentsReusableView: ArticleCommentsReusableViewInputDelegate {
    
    func stopAnimating() {
        updateCommentsButton.stopButtonRotation()
    }
    
}

// MARK: - Layout

extension ArticleCommentsReusableView {
    
    private func addSubviews() {
        addSubview(commentsLabel)
        addSubview(updateCommentsButton)
    }
    
    private func makeConstraints() {
        commentsLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.left.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(2)
        }
        
        updateCommentsButton.snp.makeConstraints { make in
            make.centerY.equalTo(commentsLabel)
            make.trailing.equalToSuperview().inset(16)
        }
    }
    
}
