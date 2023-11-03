//
//  LoginPresenter.swift
//  ForPDA
//
//  Created by Subvert on 10.05.2023.
//

import Foundation
import Factory
import WebKit

protocol LoginPresenterProtocol {
    func textChanged(to value: String, in textField: LoginView.LoginTextFields)
    func getCaptcha() async
    func login() async
}

final class LoginPresenter: LoginPresenterProtocol {
    
    // MARK: - Proeprties
    
    @Injected(\.authService) private var authService
    @Injected(\.userService) private var userService
    @Injected(\.parsingService) private var parser
    @Injected(\.settingsService) private var settings
    @Injected(\.analyticsService) private var analytics
    
    weak var view: LoginVCProtocol?
    
    lazy var loginData: [String: String] = [
        "return": URL.fourpda.absoluteString,
        "login": "",
        "password": "",
        "captcha-time": "",
        "captcha-sig": "",
        "captcha": "",
        "remember": "1",
        "hidden": "0"
    ]
    
    // MARK: - Lifecycle
    
    init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(cookiesChanged(_:)),
            name: .NSHTTPCookieManagerCookiesChanged, object: nil
        )
    }
    
    // MARK: - Notifications
    
    @objc private func cookiesChanged(_ notification: NSNotification) {
        // swiftlint:disable force_cast
        let cookies = (notification.object as! HTTPCookieStorage).cookies ?? []
        // swiftlint:enable force_cast
        
        // Saving cookies when we've got three or more of them, for explanation look into AppDelegate
        if cookies.count >= 3 {
            var cookiesArray: [Cookie] = []
            for cookie in cookies {
                cookiesArray.append(Cookie(cookie))
            }
            
            do {
                let encodedCookies = try JSONEncoder().encode(cookiesArray)
                settings.setCookiesAsData(encodedCookies)
            } catch {
                print("[ERROR] Failed to encode cookies in LoginPresenter")
            }
            
            for cookie in HTTPCookieStorage.shared.cookies ?? [] {
                DispatchQueue.main.async {
                    WKWebsiteDataStore.default().httpCookieStore.setCookie(cookie)
                }
            }
        } else if cookies.count != 0 {
            settings.logout()
        }
    }
    
    // MARK: - Public Functions
    
    func textChanged(to value: String, in textField: LoginView.LoginTextFields) {
        switch textField {
        case .login:    loginData["login"] = value
        case .password: loginData["password"] = value
        case .captcha:  loginData["captcha"] = value
        }
    }
    
    @MainActor
    func getCaptcha() async {
        do {
            let response = try await authService.captcha()
            
            guard let captchaResponse = parser.parseCaptcha(from: response) else {
                view?.showError(message: R.string.localizable.alreadyLoggedIn())
                return
            }
            
            self.loginData["captcha-time"] = captchaResponse.time
            self.loginData["captcha-sig"] = captchaResponse.sig
            
            guard let url = URL(string: captchaResponse.url) else {
                view?.showError(message: R.string.localizable.captchaUploadingFailed())
                return
            }
            view?.updateCaptcha(fromURL: url)
            
        } catch {
            view?.showError(message: R.string.localizable.loginFailedUnknownReasons())
        }
    }
    
    @MainActor
    func login() async {
        view?.showLoading(true)
        
        do {
            let response = try await authService.login(multipart: loginData)
            let parsed = parser.parseLogin(from: response)
            
            if parsed.loggedIn {
                analytics.event(Event.Login.loginSuccess.rawValue)
                let userId = parser.parseUserId(from: response)
                await getUser(id: userId)
                
                if let authKey = parser.parseAuthKey(from: response) {
                    settings.setAuthKey(authKey)
                } else {
                    print("[ERROR] Failed to retrieve auth key after successful login")
                }
                
            } else {
                analytics.event(Event.Login.loginFailed.rawValue)
                guard let message = parsed.errorMessage else {
                    // view?.showError(message: "Попробуйте ввести капчу еще раз")
                    view?.showError(message: R.string.localizable.loginFailedUnknownReasons())
                    view?.clearCaptcha()
                    await getCaptcha()
                    return
                }
                
                if message == "Введено неверное число с картинки. Попробуйте ещё раз." {
                    view?.clearCaptcha()
                    updateCaptcha(from: response)
                }
                view?.showError(message: message)
            }
        } catch {
            view?.showError(message: R.string.localizable.loginFailedUnknownReasons())
            await getCaptcha()
        }
    }
    
    @MainActor
    private func getUser(id: String) async {
        do {
            let response = try await userService.user(id: id)
            let user = parser.parseUser(from: response)
            
            if let userData = try? JSONEncoder().encode(user) {
                settings.setUser(userData)
            } else {
                print("[ERROR] Failed to encode user data after successful login")
            }
            
            view?.showLoading(false)
            view?.dismissLogin()
            
        } catch {
            view?.showError(message: R.string.localizable.loginFailedUnknownReasons())
            await getCaptcha()
        }
    }
    
    // MARK: - Private Functions
    
    private func updateCaptcha(from htmlString: String) {
        if let captchaResponse = parser.parseCaptcha(from: htmlString) {
            loginData["captcha-time"] = captchaResponse.time
            loginData["captcha-sig"] = captchaResponse.sig
            view?.updateCaptcha(fromURL: URL(string: captchaResponse.url)!)
        }
    }
}
