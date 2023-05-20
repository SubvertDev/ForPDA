//
//  MenuVC.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//
//

import UIKit
import SwiftSoup

enum Account {
    case unauthorized
    case logged
}

protocol MenuVCProtocol: AnyObject {
    func showDefaultError()
}

final class MenuVC: PDAViewController<MenuView> {
    
    private let viewModel: MenuVMProtocol
    private var state = Account.unauthorized
    
    // MARK: - Lifecycle
    
    init(viewModel: MenuVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myView.tableView.dataSource = self
        myView.tableView.delegate = self
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
//        checkAuth()
    }
    
    // MARK: - Private Functions
    
    private func checkAuth() {
//        loadCookies()
        
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
        
        for cookie in HTTPCookieStorage.shared.cookies! where cookie.value.count > 8 {
            print("authkey \(cookie.value)")
            UserDefaults.standard.set(cookie.value, forKey: "authKey")
        }
    }
}

// MARK: - DataSource & Delegates

extension MenuVC: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.sections[section].options.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? 60 : 46
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = viewModel.sections[indexPath.section].options[indexPath.row]
        
        switch model.self {
        case .authCell:
            let cell = tableView.dequeueReusableCell(withClass: MenuAuthCell.self)
            return cell
            
        case .staticCell(model: let model):
            let cell = tableView.dequeueReusableCell(withClass: MenuSettingsCell.self)
            cell.set(with: model)
            return cell
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = viewModel.sections[indexPath.section].options[indexPath.row]
        switch model.self {
        case .authCell(model: let model):
            model.handler()
            
        case .staticCell(model: let model):
            model.handler()
            
        default:
            break
        }
    }
}

//extension MenuVC: MenuViewDelegate {
//    func loginTapped() {
//        if state == .unauthorized {
//            viewModel.showLoginScreen()
//        } else {
//            myView.logoutButton.isHidden = false
////            let profileVC = ProfileVC()
////            navigationController?.pushViewController(profileVC, animated: true)
//        }
//    }
//
//    func logoutTapped() {
////        let authKey = UserDefaults.standard.string(forKey: "authKey")!
////        AF.request(URL(string: "https://4pda.to/forum/index.php?act=logout&CODE=03&k=\(authKey)")!).response { response in
////            switch response.result {
////            case .success(let data):
////                let htmlString = String(data: data!, encoding: .windowsCP1252)!
////                let parsed = try! SwiftSoup.parse(htmlString)
////                print(parsed)
////
////                HTTPCookieStorage.shared.cookies!.forEach(HTTPCookieStorage.shared.deleteCookie(_:))
////                UserDefaults.standard.removeObject(forKey: "savedCookies")
////
////            case .failure(let error):
////                print(error)
////            }
////        }
//    }
//}

extension MenuVC: MenuVCProtocol {
    
    func showDefaultError() {
        let alert = UIAlertController(title: R.string.localizable.whoops(),
                                      message: R.string.localizable.notDoneYet(),
                                      preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
}
