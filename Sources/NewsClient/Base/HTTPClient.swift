//
//  HTTPClient.swift
//  ForPDA
//
//  Created by Subvert on 19.10.2023.
//

import UIKit
import WebKit
import Factory

// MARK: - New Implementation

// MARK: - Old Implementation

protocol HTTPClientProtocol {
    func request(endpoint: Endpoint) async throws -> String
}

class HTTPClient: NSObject, HTTPClientProtocol {
    
    // MARK: - Properties
    
//    @Injected(\.settingsService) private var settingsService
    
    private lazy var webView: WKWebView = {
        // swiftlint:disable force_cast
//        let sceneDelegate = UIApplication.shared.connectedScenes.first!.delegate as! SceneDelegate
//        let webView = sceneDelegate.webView
        webView.navigationDelegate = self
        return webView
        // swiftlint:enable force_cast
    }()
    
    private var continuation: CheckedContinuation<String, Error>?
    
}

extension HTTPClient {
    
    // MARK: - Generic
    
    func request(endpoint: Endpoint) async throws -> String {
        // Workaround for news deeplinking, may intersect other requests in the future, need testing (todo)
//        if endpoint.path == "" && settingsService.getIsDeeplinking() {
//            return try await fastRequest(endpoint: endpoint)
//        }
        
        // Test later (todo)
        // if (endpoint as? NewsEndpoint != nil) && settings.getIsDeeplinking() {
        //     return try await fastRequest(endpoint: endpoint)
        // }
        
        // Totally needs refactoring (todo)
        switch endpoint {
        case let newsEndpoint as NewsEndpoint:
            switch newsEndpoint {
            case .news, .article:
                return try await fastRequest(endpoint: endpoint)
//                if settingsService.getFastLoadingSystem() {
//                    return try await fastRequest(endpoint: endpoint)
//                } else {
//                    // Redelegation after use of WebVC
//                    await MainActor.run { webView.navigationDelegate = self }
//                    return try await slowRequest(endpoint: endpoint)
//                }
            case .comments:
                return ""
//                if settingsService.getShowLikesInComments() {
//                    return try await slowRequest(endpoint: endpoint)
//                } else {
//                    return try await fastRequest(endpoint: endpoint)
//                }
            }
        default:
            if endpoint.forceFLS {
                return try await fastRequest(endpoint: endpoint)
            } else {
                return try await slowRequest(endpoint: endpoint)
            }
        }
    }
    
    // MARK: - Fast Request
    
    /// Fast request (FLS) utilizes URLSession as the source of data
    private func fastRequest(endpoint: Endpoint) async throws -> String {
        let request = try makeRequest(endpoint: endpoint)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse else {
            throw RequestError.badResponse
        }
        
        switch response.statusCode {
        case 200...299:
            return try convertDataToCyrillicString(data)
            
        default:
            throw RequestError.unexpectedStatusCode(response.statusCode)
        }
    }
    
    // MARK: - Slow Request
    
    /// Slow request (SLS) utilizes WKWebView as the source of data
    private func slowRequest(endpoint: Endpoint) async throws -> String {
        let request = try makeRequest(endpoint: endpoint)
        return try await load(request)
    }
    
    @MainActor
    private func load(_ request: URLRequest) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            if self.continuation != nil {
                // Workaround for case when previous article is still loading,
                // so continuation doesn't leak, need testing
                self.continuation?.resume(returning: "")
            }
            self.continuation = continuation
            self.webView.load(request)
        }
    }
}

// MARK: - WKNavigationDelegate

extension HTTPClient: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
//            if settingsService.getShowLikesInComments() {
//                // 0.3 sec delay to load comments, make tweakable (todo)
//                try await Task.sleep(nanoseconds: 0_500_000_000)
//            }
            if let document = try await webView.evaluateJavaScript("document.documentElement.outerHTML") as? String {
                if document.contains("Всё в порядке, но") {
                    continuation?.resume(throwing: RequestError.unexpectedStatusCode(403))
                } else {
                    continuation?.resume(returning: document)
                }
            } else {
                continuation?.resume(throwing: RequestError.jsEvaluationFailed)
            }
            continuation = nil
        }
    }
}

// MARK: - Helpers

extension HTTPClient {
    
    private func makeRequest(endpoint: Endpoint) throws -> URLRequest {
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host
        urlComponents.path = endpoint.path
        
        if let query = endpoint.query {
            urlComponents.queryItems = query.map({
                URLQueryItem(name: $0, value: $1)
            })
        }
        
        guard let url = urlComponents.url else {
            throw RequestError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        endpoint.header?.forEach {
            request.addValue($0.header.value, forHTTPHeaderField: $0.header.field)
        }
        
        if let _ = endpoint.multipart {
            // Legacy handling of multipart, needs update (todo)
//            MultipartFormDataRequest().modifyRequest(&request, with: multipart)
        } else {
            if let body = endpoint.body {
                request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            }
        }
        
        return request
    }
    
    /// Helper method to extract cyrillic string without artifacts on FLS
    private func convertDataToCyrillicString(_ data: Data) throws -> String {
        guard let string = String(data: data, encoding: .isoLatin1) else { throw RequestError.decodingFailed }
        
        let string2 = string.replacingOccurrences(of: "\u{98}", with: "")
        let string3 = string2.replacingOccurrences(of: "\u{ad}", with: "") // optionally
        let string4 = string3.replacingOccurrences(of: "\u{a0}", with: "") // optionally
        
        guard let data2 = string4.data(using: .isoLatin1) else { throw RequestError.decodingFailed }
        guard let stringFinal = String(data: data2, encoding: .windowsCP1251) else { throw RequestError.decodingFailed }
        return stringFinal
    }
    
    /// Backup version of 'convertDataToCyrillicString' function
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
