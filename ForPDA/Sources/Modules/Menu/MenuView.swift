//
//  ProfileView.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//

import UIKit

protocol MenuViewDelegate: AnyObject {
    func loginTapped()
    func logoutTapped()
}

final class MenuView: UIView {
    
    // MARK: - Views
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.sectionHeaderHeight = 0
        tableView.alwaysBounceVertical = false
        tableView.register(cellWithClass: MenuAuthCell.self)
        tableView.register(cellWithClass: MenuSettingsCell.self)
        return tableView
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        addSubview(tableView)
    }
    
    private func makeConstraints() {
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}
