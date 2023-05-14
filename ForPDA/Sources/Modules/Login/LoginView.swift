//
//  LoginView.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//

import UIKit

protocol LoginViewDelegate: AnyObject {
    func loginTapped()
}

final class LoginView: UIView {
    
    let loginTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "login"
        return textField
    }()
    
    let passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "password"
        return textField
    }()
    
    let captchaImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    let captchaTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "captcha"
        return textField
    }()
    
    lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Авторизироваться", for: .normal)
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    var delegate: LoginViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        
        addSubviews()
        makeConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func loginTapped() {
        delegate?.loginTapped()
    }
    
    private func addSubviews() {
        addSubview(loginTextField)
        addSubview(passwordTextField)
        addSubview(captchaImageView)
        addSubview(captchaTextField)
        addSubview(loginButton)
    }
    
    private func makeConstraints() {
        loginTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(safeAreaLayoutGuide).inset(64)
        }
        
        passwordTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(loginTextField.snp.bottom).offset(8)
        }
        
        captchaImageView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(passwordTextField.snp.bottom).offset(8)
            make.height.equalTo(100)
        }
        
        captchaTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(captchaImageView.snp.bottom).offset(8)
        }
        
        loginButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(captchaTextField.snp.bottom).offset(8)
            make.height.equalTo(100)
        }
    }
}
