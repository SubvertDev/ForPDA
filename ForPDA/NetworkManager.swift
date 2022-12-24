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

final class NetworkManager {
    
    static let shared = NetworkManager()
    
    private let startPageURL = URL(string: "https://4pda.to/")!
    
    private init() {}
    
    func getStartPage() async throws -> Document {
        let data = try await AF.request(startPageURL).serializingData().value
        let htmlString = convertDataToCyrillicString(data)
        let parsed = try SwiftSoup.parse(htmlString)
        return parsed
    }
    
    func getArticlePage(url: URL) async throws -> Document {
        let data = try await AF.request(url).serializingData().value
        let htmlString = convertDataToCyrillicString(data)
        let parsed = try SwiftSoup.parse(htmlString)
        return parsed
    }
    
    private func convertDataToCyrillicString(_ data: Data) -> String {
        let string = String(data: data, encoding: .isoLatin1)!
        
        let string2 = string.replacingOccurrences(of: "\u{98}", with: "")
        let string3 = string2.replacingOccurrences(of: "\u{ad}", with: "")
        let string4 = string3.replacingOccurrences(of: "\u{a0}", with: "")
        
        let data2 = string4.data(using: .isoLatin1)!
        let stringFinal = String(data: data2, encoding: .windowsCP1251)!
        
        return stringFinal
    }
}
