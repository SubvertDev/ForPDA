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
    
    let tableView: UITableView = {
        let tableView = UITableView()
        return tableView
    }()
    
    lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Авторизироваться", for: .normal)
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.isHidden = true
        button.setTitle("Выйти из аккаунта", for: .normal)
        button.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        return button
    }()
    
    var delegate: MenuViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func loginTapped() {
        delegate?.loginTapped()
    }
    
    @objc func logoutTapped() {
        delegate?.logoutTapped()
    }
    
    private func addSubviews() {
        addSubview(loginButton)
        addSubview(logoutButton)
    }
    
    private func makeConstraints() {
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(64)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
        
        logoutButton.snp.makeConstraints { make in
            make.top.equalTo(loginButton.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
    }
    
}
