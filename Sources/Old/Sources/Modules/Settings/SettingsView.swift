//
//  SettingsView.swift
//  ForPDA
//
//  Created by Subvert on 20.05.2023.
//

import UIKit

final class SettingsView: UIView {
    
    // MARK: - Views
    
    private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.alwaysBounceVertical = false
        tableView.register(cellWithClass: MenuAuthCell.self)
        tableView.register(cellWithClass: MenuSettingsCell.self)
        tableView.register(cellWithClass: SettingsSwitchCell.self)
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
