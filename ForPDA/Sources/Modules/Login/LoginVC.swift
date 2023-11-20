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

final class LoginVC: PDAViewControllerWithView<LoginView> {
    
    // MARK: - Properties
    
    private let presenter: LoginPresenterProtocol
    
    var interceptorCompletionBlock: ((_: RoutingResult) -> Void)? {
        willSet {
            guard let completion = interceptorCompletionBlock else { return }
            let description = "New completion block was set. Previous navigation process should be halted."
            completion(.failure(RoutingError.generic(.init(description))))
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
        
        Task {
            await presenter.getCaptcha()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            interceptorCompletionBlock?(.failure(RoutingError.generic(.init("User tapped back button"))))
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
        NukeExtensions.loadImage(with: url, into: myView.captchaImageView) { [weak self] _ in
            guard let self else { return }
            if UIScreen.main.traitCollection.userInterfaceStyle.rawValue == 2 {
                invertImage()
            }
        }
    }
    
    func clearCaptcha() {
        myView.captchaTextField.text = nil
    }
    
    func showError(message: String) {
        myView.errorMessageLabel.text = message
        showLoading(false)
    }
    
    func showLoading(_ state: Bool) {
        navigationController?.navigationBar.isUserInteractionEnabled = !state
        navigationController?.navigationBar.tintColor = state ? .gray : .label
        myView.loginButton.showLoading(state)
    }
    
    func dismissLogin() {
        interceptorCompletionBlock?(.success)
    }
}

// MARK: - LoginViewDelegate

extension LoginVC: LoginViewDelegate {
    
    func loginTapped() {
        Task {
            await presenter.login()
        }
    }
    
    func captchaImageTapped() {
        Task {
            await presenter.getCaptcha()
        }
    }
}
