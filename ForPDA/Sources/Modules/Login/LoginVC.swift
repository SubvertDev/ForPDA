//
//  LoginVC.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//

import UIKit
import Factory
import NukeExtensions
import RouteComposer

protocol LoginVCProtocol: AnyObject {
    func updateCaptcha(fromURL url: URL)
    func clearCaptcha()
    func showError(message: String)
    func showLoading(_ state: Bool)
    func dismissLogin()
}

final class LoginVC: PDAViewController<LoginView> {
    
    // MARK: - Properties
    
    private let presenter: LoginPresenterProtocol
    
    var interceptorCompletionBlock: ((_: RoutingResult) -> Void)? {
        willSet {
            guard let completion = interceptorCompletionBlock else { return }
            completion(.failure(RoutingError.generic(.init("New completion block was set. " +
                    "Previous navigation process should be halted."))))
        }
    }
    
    // MARK: - Lifecycle
    
    init(presenter: LoginPresenterProtocol) {
        self.presenter = presenter
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDelegates()
        configureActions()
        configureNavBar()
        
        presenter.getCaptcha()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        if isMovingFromParent {
            interceptorCompletionBlock?(.failure(FailingRouterIgnoreError(
                underlyingError: RoutingError.generic(.init("User tapped back button")))))
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        invertImage()
    }
    
    // MARK: - Configure
    
    private func configureDelegates() {
        myView.delegate = self
    }
    
    private func configureActions() {
        myView.loginTextField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        myView.passwordTextField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
        myView.captchaTextField.addTarget(self, action: #selector(textFieldEditingChanged(_:)), for: .editingChanged)
    }
    
    private func configureNavBar() {
        title = R.string.localizable.authorization()
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    private func invertImage() {
        guard let originalImage = myView.captchaImageView.image else { return }
        guard let currentFilter = CIFilter(name: "CIColorInvert") else { return }
        currentFilter.setValue(CIImage(image: originalImage), forKey: kCIInputImageKey)
        guard let output = currentFilter.outputImage else { return }
        guard let cgImage = CIContext(options: nil).createCGImage(output, from: output.extent) else { return }
        let (scale, imageOrientation) = (originalImage.scale, originalImage.imageOrientation)
        myView.captchaImageView.image = UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
    
    // MARK: - Actions
    
    @objc private func textFieldEditingChanged(_ textField: UITextField) {
        switch textField.tag {
        case 0: presenter.textChanged(to: textField.text ?? "", in: .login)
        case 1: presenter.textChanged(to: textField.text ?? "", in: .password)
        case 2: presenter.textChanged(to: textField.text ?? "", in: .captcha)
        default: break
        }
    }
}

// MARK: - LoginVCProtocol

extension LoginVC: LoginVCProtocol {
    
    func updateCaptcha(fromURL url: URL) {
        DispatchQueue.main.async {
            NukeExtensions.loadImage(with: url, into: self.myView.captchaImageView) { [weak self] _ in
                guard let self else { return }
                if UIScreen.main.traitCollection.userInterfaceStyle.rawValue == 2 {
                    invertImage()
                }
            }
        }
    }
    
    func clearCaptcha() {
        DispatchQueue.main.async {
            self.myView.captchaTextField.text = nil
        }
    }
    
    func showError(message: String) {
        DispatchQueue.main.async {
            self.myView.errorMessageLabel.text = message
            self.showLoading(false)
        }
    }
    
    func showLoading(_ state: Bool) {
        DispatchQueue.main.async {
            self.navigationController?.navigationBar.isUserInteractionEnabled = !state
            self.navigationController?.navigationBar.tintColor = state ? .gray : .systemBlue
            self.myView.loginButton.showLoading(state)
        }
    }
    
    func dismissLogin() {
        DispatchQueue.main.async {
            self.interceptorCompletionBlock?(.success)
        }
    }
}

// MARK: - LoginViewDelegate

extension LoginVC: LoginViewDelegate {
    func loginTapped() {
        presenter.login()
    }
    
    func captchaImageTapped() {
        presenter.getCaptcha()
    }
}
