//
//  ArticleView.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import SFSafeSymbols

protocol ArticleViewDelegate: AnyObject {
    func updateCommentsButtonTapped()
}

final class ArticleView: UIView {
    
    // MARK: - Views
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private(set) var articleImage: PDAResizingImageView = {
        let imageView = PDAResizingImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
//        imageView.addoverlay()
        return imageView
    }()
    
    private(set) var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 25, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 2.0
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = .zero
        label.layer.masksToBounds = false
        return label
    }()
    
    private(set) var hideView: UIView = {
        let view = UIView()
        return view
    }()
    
    private(set) var loadingIndicator: ProgressView = {
        let progress = ProgressView(colors: [.label], lineWidth: 4)
        progress.isAnimating = true
        return progress
    }()
    
    private(set) var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
        stackView.spacing = 16
        return stackView
    }()
    
    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .label
        return view
    }()
    
    private(set) var commentsLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.comments(0)
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private(set) lazy var updateCommentsButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(weight: .bold)
        let image = UIImage(systemSymbol: .arrowTriangle2Circlepath, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(updateCommentsButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private(set) var commentsContainer = UIView()
    
    // MARK: - Properties
    
    weak var delegate: ArticleViewDelegate?
    
    // MARK: - View Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Public Functions
    
    func stopLoading() {
        hideView.isHidden = true
        loadingIndicator.isHidden = true
    }
    
    func removeComments() {
        separator.removeFromSuperview()
        commentsLabel.removeFromSuperview()
        commentsContainer.removeFromSuperview()
    }
    
    // MARK: - Actions
    
    @objc private func updateCommentsButtonTapped() {
        if !updateCommentsButton.isButtonAnimatingNow {
            delegate?.updateCommentsButtonTapped()
            updateCommentsButton.rotate360Degrees(duration: 1, repeatCount: .infinity)
        }
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        addSubview(scrollView)
        addSubview(hideView)
        hideView.addSubview(loadingIndicator)
        scrollView.addSubview(contentView)
        contentView.addSubview(articleImage)
        contentView.addSubview(titleLabel)
        contentView.addSubview(stackView)
        contentView.addSubview(separator)
        contentView.addSubview(commentsLabel)
        contentView.addSubview(updateCommentsButton)
        contentView.addSubview(commentsContainer)
    }
    
    private func makeConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.width.equalToSuperview()
        }
        
        let hideViewTopInset = UIScreen.main.bounds.width * 0.6
        hideView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(hideViewTopInset)
            make.bottom.leading.trailing.equalTo(scrollView)
        }
        
        loadingIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-64)
            make.size.equalTo(44)
        }
        
        contentView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(self).priority(700)
            make.width.equalTo(self)
        }
        
        articleImage.snp.makeConstraints { make in
            make.top.horizontalEdges.width.equalToSuperview()
            make.height.equalTo(articleImage.snp.width).multipliedBy(0.6)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.bottom.equalTo(articleImage).inset(8)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(articleImage.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(1000).priority(701)
        }
        
        separator.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(1)
        }
        
        commentsLabel.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(12)
        }
        
        updateCommentsButton.snp.makeConstraints { make in
            make.centerY.equalTo(commentsLabel)
            make.trailing.equalToSuperview().inset(16)
        }
        
        commentsContainer.snp.makeConstraints { make in
            make.top.equalTo(commentsLabel.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().inset(16)
        }
    }
}
