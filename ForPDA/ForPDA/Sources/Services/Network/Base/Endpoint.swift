//
//  Endpoint.swift
//  ForPDA
//
//  Created by Subvert on 19.10.2023.
//

import Foundation

protocol Endpoint {
    var forceFLS: Bool { get }
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [HTTPHeader]? { get }
    var body: [String: Any]? { get }
    var multipart: [String: String]? { get }
    var query: [String: String]? { get }
}

extension Endpoint {
    /// Forces Fast Loading System if not stated otherwise (e.g. news)
    /// Has sort of overriding in HTTPClient request function
    var forceFLS: Bool {
        return true
    }
    
    var scheme: String {
        return "https"
    }

    // Add remote check to replace host (todo)
    var host: String {
        return "4pda.to"
    }
    
    var absoluteString: String {
        var urlComponents = URLComponents()
        urlComponents.scheme = scheme
        urlComponents.host = host
        urlComponents.path = path
        
        if let query = query {
            urlComponents.queryItems = query.map({
                URLQueryItem(name: $0, value: $1)
            })
        }
        
        return urlComponents.url?.absoluteString ?? "Absolute string components error"
    }
}
