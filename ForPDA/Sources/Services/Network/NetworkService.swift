//
//  NetworkManager.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import Factory

import SwiftSoup // -----

enum NetworkError: Error {
    case unableToComplete(Error?)
    case invalidResponse
    case unhandledResponse(Int)
    case invalidData
    case invalidDecoding
}

final class NetworkService {
    
    private let startPageURL = URL(string: "https://4pda.to/")!
    
    // func getArticles(atPage number: Int = 1) async throws -> Document {
    //     let url = URL(string: "https://4pda.to/page/\(number)")!
    //     let (data, _) = try await URLSession.shared.data(from: url)
    //     let htmlString = try convertDataToCyrillicString(data)
    //     let parsed = try SwiftSoup.parse(htmlString)
    //     return parsed
    // }
    
    // MARK: - News
    
    func getArticles(page: Int = 1, completion: @escaping (Result<String, NetworkError>) -> Void) {
        makeRequest(request: .news(page: page), completion: completion)
    }
    
    func getArticlePage(url: URL) async throws -> Document {
        let (data, _) = try await URLSession.shared.data(from: url)
        let htmlString = try convertDataToCyrillicString(data)
        let parsed = try SwiftSoup.parse(htmlString)
        return parsed
    }
    
    // MARK: - Login
    
    func getCaptcha(completion: @escaping (Result<String, NetworkError>) -> Void) {
        makeRequest(request: .captcha, completion: completion)
    }
    
    // MARK: - Generic
    
    func makeRequest(request: URLRequest, completion: @escaping (Result<String, NetworkError>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(.unableToComplete(error)))
                return
            }
            
            guard let response = (response as? HTTPURLResponse) else {
                completion(.failure(.invalidResponse))
                return
            }
            
            guard 200...299 ~= response.statusCode else {
                completion(.failure(.unhandledResponse(response.statusCode)))
                return
            }
            
            guard let data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let parsedResponse = try self.convertDataToCyrillicString(data)
                completion(.success(parsedResponse))
            } catch {
                completion(.failure(.invalidDecoding))
            }
        }.resume()
    }
    
    // MARK: - Helpers
    
    private func convertDataToCyrillicString(_ data: Data) throws -> String {
        guard let string = String(data: data, encoding: .isoLatin1) else { throw NetworkError.invalidDecoding }
        
        let string2 = string.replacingOccurrences(of: "\u{98}", with: "")
        let string3 = string2.replacingOccurrences(of: "\u{ad}", with: "") // optionally
        let string4 = string3.replacingOccurrences(of: "\u{a0}", with: "") // optionally
        
        guard let data2 = string4.data(using: .isoLatin1) else { throw NetworkError.invalidDecoding }
        guard let stringFinal = String(data: data2, encoding: .windowsCP1251) else { throw NetworkError.invalidDecoding}
        
        return stringFinal
    }
    
    // Backup version
    private func convertToUTF8(_ data: Data) -> String {
        var data = data
        data.removeAll { $0 == 0x98 }
        
        guard let cfstring = CFStringCreateFromExternalRepresentation(nil, data as CFData, CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue)) else { preconditionFailure() }
        
        let size = CFStringGetMaximumSizeForEncoding(CFStringGetLength(cfstring), CFStringBuiltInEncodings.UTF8.rawValue)
        let buffer = malloc(size).bindMemory(to: CChar.self, capacity: size)
        guard CFStringGetCString(cfstring, buffer, size, CFStringBuiltInEncodings.UTF8.rawValue) else {
            free(buffer)
            preconditionFailure()
        }
        
        let string = String(cString: buffer)
        free(buffer)
        
        return string
    }
}
