//
//  ProfileVC.swift
//  ForPDA
//
//  Created by Subvert on 13.12.2022.
//
//  swiftlint:disable all
//  todo disable disables

import UIKit
import SwiftSoup
import Nuke
import NukeExtensions

final class ProfileVC: PDAViewController<ProfileView> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getProfile()
    }
    
    private func getProfile() {
//        let userId = UserDefaults.standard.string(forKey: "userId")!
//        AF.request(URL(string: "https://4pda.to/forum/index.php?showuser=\(userId)")!).response { response in
//            switch response.result {
//            case .success(let data):
//                let htmlString = String(data: data!, encoding: .windowsCP1252)!
//                let parsed = try! SwiftSoup.parse(htmlString)
//                print(parsed)
//                
//                let userBox = try! parsed.select("[class=user-box]").get(0)
//                var imageUrl = try! userBox.select("img[src]").attr("src")
//                imageUrl = "https:" + imageUrl
//                let title = try! userBox.select("img[src]").attr("title")
//                
//                DispatchQueue.main.async {
//                    NukeExtensions.loadImage(with: URL(string: imageUrl)!, into: self.myView.profileImageView)
//                    self.myView.titleLabel.text = title
//                }
//                
//            case .failure(let error):
//                print(error)
//            }
//        }
    }
    
}
