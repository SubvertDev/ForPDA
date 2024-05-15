//
//  LoginView.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//

import UIKit

protocol LoginViewDelegate: AnyObject {
    func loginTapped()
    func captchaImageTapped()
}

final class LoginView: UIView {
    
    // MARK: - Enums
    
    enum LoginTextFields {
        case login
        case password
        case captcha
    }
    
    // MARK: - UI
    
    private(set) var loginTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = R.string.localizable.loginTextFieldPlaceholder()
        textField.textContentType = .username
        textField.borderStyle = .roundedRect
        textField.tag = 0
        return textField
    }()
    
    private(set) var passwordTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = R.string.localizable.passwordTextFieldPlaceholder()
        textField.textContentType = .password
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        textField.tag = 1
        return textField
    }()
    
    private(set) var captchaImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    private(set) var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        return indicator
    }()
    
    private(set) var captchaTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = R.string.localizable.captchaTextFieldPlaceholder()
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.tag = 2
        return textField
    }()
    
    private(set) var errorMessageLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.numberOfLines = 0
        return label
    }()
    
    private(set) lazy var loginButton: LoadingButton = {
        let button = LoadingButton(type: .system)
        button.setTitle(R.string.localizable.login(), for: .normal)
        button.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Properties
    
    weak var delegate: LoginViewDelegate?
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        
        addSubviews()
        makeConstraints()
        setupToolbar()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(captchaImageTapped))
        captchaImageView.addGestureRecognizer(tap)
        captchaImageView.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Actions
    
    @objc private func loginTapped() {
        delegate?.loginTapped()
    }
    
    @objc private func captchaImageTapped() {
        delegate?.captchaImageTapped()
    }
    
    @objc private func doneButtonTapped() {
        endEditing(true)
    }
    
    // MARK: - Layout
    
    private func addSubviews() {
        [loginTextField,
         passwordTextField,
         activityIndicator,
         captchaImageView,
         captchaTextField,
         errorMessageLabel,
         loginButton
        ].forEach { addSubview($0) }
    }
    
    private func makeConstraints() {
        let isSE = UIScreen.main.bounds.height <= 667
        loginTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(safeAreaLayoutGuide).inset(isSE ? 16 : 64)
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
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(captchaImageView)
        }
        
        captchaTextField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalTo(captchaImageView.snp.bottom).offset(8)
        }
        
        errorMessageLabel.snp.makeConstraints { make in
            make.top.equalTo(captchaTextField.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(errorMessageLabel.snp.bottom).offset(16)
            make.horizontalEdges.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }
    }
    
    private func  setupToolbar() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: R.string.localizable.done(), style: .done, target: self, action: #selector(doneButtonTapped))
        toolbar.items = [flexibleSpace, doneButton]
        captchaTextField.inputAccessoryView = toolbar
        loginTextField.inputAccessoryView = toolbar
        passwordTextField.inputAccessoryView = toolbar
    }
}

final class LoadingButton: UIButton {
    
    private var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.style = .large
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var originalButtonText: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showLoading(_ state: Bool) {
        if state {
            setTitle("", for: .normal)
            activityIndicator.startAnimating()
            originalButtonText = titleLabel?.text
        } else {
            setTitle(originalButtonText, for: .normal)
            activityIndicator.stopAnimating()
        }
    }
}
