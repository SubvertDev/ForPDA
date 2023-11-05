//
//  RequestError.swift
//  ForPDA
//
//  Created by Subvert on 19.10.2023.
//

import Foundation

enum RequestError: Error {
    case decodingFailed
    case invalidURL
    case badResponse
    case unexpectedStatusCode(_ code: Int)
    case jsEvaluationFailed
    case unknown
    
    var customMessage: String {
        switch self {
        case .decodingFailed:
            return "Decoding failed"
        case .invalidURL:
            return "Invalid URL"
        case .badResponse:
            return "Bad response"
        case .unexpectedStatusCode(let code):
            return "Unexpected code (\(code))"
        case .jsEvaluationFailed:
            return "JS evaluation failed"
        default:
            return "Unknown error"
        }
    }
}
