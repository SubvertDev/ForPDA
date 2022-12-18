//
//  NetworkManager.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import Alamofire
import SwiftSoup

enum NetworkError {
    
}

//protocol NetworkManagerProtocol: AnyObject {
//    func getStartPage() -> Document
//}

final class NetworkManager { // NetworkManagerProtocol {
    
    static let shared = NetworkManager()
    
    private let startPageURL = URL(string: "https://4pda.to/")!
    
    private init() {}
    
    func getStartPage() async throws -> Document {
        let data = try await AF.request(startPageURL).serializingData().value
        let htmlString = String(data: data, encoding: .windowsCP1252)!
        let parsed = try! SwiftSoup.parse(htmlString)
        return parsed
    }
    
    func getArticlePage(url: URL) async throws -> Document {
        let data = try await AF.request(url).serializingData().value
        let htmlString = String(data: data, encoding: .windowsCP1252)!
        let parsed = try! SwiftSoup.parse(htmlString)
        return parsed
    }
    
}
