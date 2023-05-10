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
    
//    func getArticles(atPage number: Int = 1) async throws -> Document {
//        let url = URL(string: "https://4pda.to/page/\(number)")!
//        let (data, _) = try await URLSession.shared.data(from: url)
//        let htmlString = try convertDataToCyrillicString(data)
//        let parsed = try SwiftSoup.parse(htmlString)
//        return parsed
//    }
    
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
//        print(request.url!.absoluteString)
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

// MARK: - HTTPMethod

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

// MARK: - URLComponents

extension URLComponents {
    init(scheme: String = "https",
         host: String = "www.4pda.to",
         path: String,
         queryItems: [URLQueryItem]? = nil) {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = queryItems
        self = components
    }
}

extension URLComponents {
    static func news(page: Int) -> Self {
        Self(path: "/page/\(page)/")
    }
    
    static func article(path: String) -> Self {
        Self(path: "\(path)")
    }
    
    static var captcha: Self {
        Self(path: "/forum/index.php", queryItems: [URLQueryItem(name: "act", value: "auth")])
    }
}

// MARK: - URLRequest

extension URLRequest {
    init(components: URLComponents) {
        guard let url = components.url else {
            preconditionFailure("Unable to get URL from URLComponents: \(components)")
        }

        self = Self(url: url)
    }

    private func map(_ transform: (inout Self) -> Void) -> Self {
        var request = self
        transform(&request)
        return request
    }

    func add(httpMethod: HTTPMethod) -> Self {
        map { $0.httpMethod = httpMethod.rawValue }
    }

    func add<Body: Encodable>(body: Body) -> Self {
        map {
            do {
                $0.httpBody = try JSONEncoder().encode(body)
            } catch {
                preconditionFailure("Failed to encode request Body: \(body) due to Error: \(error)")
            }
        }
    }

    func add(data: Data?) -> Self {
        map {
            $0.httpBody = data
        }
    }

    func add(headers: [String: String]) -> Self {
        map {
            var allHTTPHeaderFields = $0.allHTTPHeaderFields ?? [:]
            
            headers.forEach { (key, value) in allHTTPHeaderFields[key] = value }
            $0.allHTTPHeaderFields = allHTTPHeaderFields
        }
    }
    
    func withNewAuthorizationToken(_ accessToken: String) -> Self {
        return self.add(headers: ["Authorization": "Bearer \(accessToken)"])
    }
}

// MARK: - Custom Requests

extension URLRequest {
    static func news(page: Int) -> Self {
        Self(components: .news(page: page))
            .add(httpMethod: .get)
    }
    
    static var captcha: Self {
        Self(components: .captcha)
            .add(httpMethod: .get)
    }
}
