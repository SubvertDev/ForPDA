//
//  NewsView.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit

protocol NewsViewDelegate {
    func refresh()
}

final class NewsView: UIView {
    
    // MARK: - Views
    
    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableHeaderView = UIView()
        tableView.register(ArticleCell.self, forCellReuseIdentifier: ArticleCell.reuseIdentifier)
        return tableView
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return control
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
    
    @objc private func refresh(_ sender: UIRefreshControl) {
        print(#function)
        delegate?.refresh()
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        addSubview(tableView)
        tableView.addSubview(refreshControl)
    }
    
    private func makeConstraints() {
        tableView.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalTo(safeAreaLayoutGuide)
        }
    }
}
