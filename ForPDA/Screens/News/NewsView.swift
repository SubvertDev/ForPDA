//
//  NewsView.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit

protocol NewsViewDelegate: AnyObject {
    func refreshControlCalled()
    func refreshButtonTapped()
}

final class NewsView: UIView {
    
    // MARK: - Views
    
    let tableView: PDATableView = {
        let tableView = PDATableView()
        tableView.tableHeaderView = UIView()
        tableView.register(cellWithClass: ArticleCell.self)
        return tableView
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshControlCalled), for: .valueChanged)
        return control
    }()
    
    let footerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 55))
    
    lazy var refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        button.setTitle("ЗАГРУЗИТЬ БОЛЬШЕ", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.addTarget(self, action: #selector(refreshButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    var delegate: NewsViewDelegate?
    
    // MARK: - View Lifecycle
    
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
    
    @objc private func refreshControlCalled(_ sender: UIRefreshControl) {
        delegate?.refreshControlCalled()
    }
    
    @objc private func refreshButtonTapped(_ sender: UIButton) {
        delegate?.refreshButtonTapped()
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        addSubview(tableView)
        tableView.addSubview(refreshControl)
        tableView.tableFooterView = footerView
        footerView.addSubview(refreshButton)
    }
    
    private func makeConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        refreshButton.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5.5)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(160)
        }
    }
}
