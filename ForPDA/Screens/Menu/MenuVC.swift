//
//  MenuVC.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//
//  swiftlint:disable all
//  todo disable disables

import UIKit
import SwiftSoup

enum Account {
    case unauthorized
    case logged
}

final class MenuVC: PDAViewController<MenuView> {
    
    var state = Account.unauthorized
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myView.delegate = self
    }
    
    private func checkAuth() {
        loadCookies()
//        AF.request(URL(string: "https://4pda.to/forum/index.php?showuser=3640948")!).response { response in
//            switch response.result {
//            case .success(let data):
//                let htmlString = String(data: data!, encoding: .windowsCP1252)!
//                let parsed = try! SwiftSoup.parse(htmlString)
//                print(parsed)
//                let log = try! parsed.select("[id=moderator-log]")
//                if !log.isEmpty() {
//                    print("already logged")
//
//                    let id = try! parsed.select("[data-toggle=dropdown]").get(0).attr("href").components(separatedBy: "=").last!
//                    print("saving id \(id)")
//                    UserDefaults.standard.set(id, forKey: "userId")
//                    self.state = .logged
//                    self.myView.loginButton.setTitle("Зайти в профиль", for: .normal)
//                    self.myView.logoutButton.isHidden = false
//                } else {
//                    print("not logged yet")
//                    self.state = .unauthorized
//                    self.myView.loginButton.setTitle("Авторизироваться", for: .normal)
//                }
//            case .failure(let error):
//                print(error)
//            }
//        }
    }
    
    func loadCookies() {
        guard let cookieArray = UserDefaults.standard.array(forKey: "savedCookies") as? [[HTTPCookiePropertyKey: Any]] else { return }
        for cookieProperties in cookieArray {
            if let cookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        
        for cookie in HTTPCookieStorage.shared.cookies! {
            if cookie.value.count > 8 {
                print("authkey \(cookie.value)")
                UserDefaults.standard.set(cookie.value, forKey: "authKey")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkAuth()
    }
}

extension MenuVC: MenuViewDelegate {
    func loginTapped() {
//        if state == .unauthorized {
//            let loginVC = LoginVC()
//            navigationController?.pushViewController(loginVC, animated: true)
//        } else {
//            myView.logoutButton.isHidden = false
//            let profileVC = ProfileVC()
//            navigationController?.pushViewController(profileVC, animated: true)
//        }
    }
    
    func logoutTapped() {
//        let authKey = UserDefaults.standard.string(forKey: "authKey")!
//        AF.request(URL(string: "https://4pda.to/forum/index.php?act=logout&CODE=03&k=\(authKey)")!).response { response in
//            switch response.result {
//            case .success(let data):
//                let htmlString = String(data: data!, encoding: .windowsCP1252)!
//                let parsed = try! SwiftSoup.parse(htmlString)
//                print(parsed)
//                
//                HTTPCookieStorage.shared.cookies!.forEach(HTTPCookieStorage.shared.deleteCookie(_:))
//                UserDefaults.standard.removeObject(forKey: "savedCookies")
//                
//            case .failure(let error):
//                print(error)
//            }
//        }
    }
}
