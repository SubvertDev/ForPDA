//
//  LoginVC.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//

import UIKit
import SwiftSoup
import Nuke
import NukeExtensions
import Alamofire

struct LoginData {
    let login: String
    let password: String
    let rememberer: Int
    let captchaTime: String
    let captchaSig: String
    let captcha: String
}

final class LoginVC: PDAViewController<LoginView> {
    
    var loginData: LoginData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myView.delegate = self
        getCaptcha()
    }
    
    private func getCaptcha() {
        AF.request(URL(string: "https://4pda.to/forum/index.php?act=auth")!).response { response in
            switch response.result {
            case .success(let data):
                let htmlString = String(data: data!, encoding: .windowsCP1252)!
                let parsed = try! SwiftSoup.parse(htmlString)
                print(parsed)
                
                if htmlString.contains("action=logout&k=") { return }
                
                let captchaTime = try! parsed.select("[name=captcha-time]").get(0).attr("value")
                let captchaSig = try! parsed.select("[name=captcha-sig]").get(0).attr("value")
                print(captchaSig, captchaTime)
                
                var linkElement = try! parsed.select("img[src]").get(0).attr("src")
                linkElement = "https:" + linkElement
                print(linkElement)
                
                DispatchQueue.main.async {
                    NukeExtensions.loadImage(with: URL(string: linkElement)!, into: self.myView.captchaImageView)
                }
                
                let data = LoginData(login: "",
                                     password: "",
                                     rememberer: 1,
                                     captchaTime: captchaTime,
                                     captchaSig: captchaSig,
                                     captcha: "")
                self.loginData = data
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func login() {
        let parameters = [
            "login": loginData.login,
            "password": loginData.password,
            "remember": "1",
            "captcha-time": loginData.captchaTime,
            "captcha-sig": loginData.captchaSig,
            "captcha": myView.captchaTextField.text!
        ] as [String : String]
        print(myView.captchaTextField.text!)
        AF.upload(multipartFormData: { multipartFormData in
            for (key, value) in parameters {
                multipartFormData.append(value.data(using: .utf8)!, withName: key)
            }
            //let string = String(describing: self.myView.captchaTextField.text!)
            //multipartFormData.append(string.data(using: .utf8)!, withName: "captcha")
        }, to: URL(string: "https://4pda.to/forum/index.php?act=auth")!, method: .post)
        .response { result in
            switch result.result {
            case .success(let success):
                let htmlString = String(data: success!, encoding: .windowsCP1252)!
                let parsed = try! SwiftSoup.parse(htmlString)
                print(parsed)
                let errors = try! parsed.select("[class=errors-list")
                if !errors.isEmpty() {
                    let error = try! errors.select("li").get(0).text().converted()
                    print(error)
                } else {
                    print("login success")
                    self.saveCookies(response: result)
                    self.navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func saveCookies(response: AFDataResponse<Data?>) {
        let headerFields = response.response?.allHeaderFields as! [String: String]
        let url = response.response?.url
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url!)
        var cookieArray = [[HTTPCookiePropertyKey: Any]]()
        for cookie in cookies {
            cookieArray.append(cookie.properties!)
        }
        UserDefaults.standard.set(cookieArray, forKey: "savedCookies")
        UserDefaults.standard.synchronize()
    }
}

extension LoginVC: LoginViewDelegate {
    func loginTapped() {
        login()
    }
}

// "https://4pda.to/forum/index.php?act=qms&code=no"
